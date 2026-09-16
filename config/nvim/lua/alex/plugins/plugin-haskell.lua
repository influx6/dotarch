-- Haskell IDE support via haskell-tools.nvim (by mrcjkb, the same author as
-- rustaceanvim). Like rustaceanvim, it fully manages the language server
-- itself, so it must NOT be registered through mason-lspconfig/lspconfig.
--
-- HLS comes from ghcup (`haskell-language-server-wrapper` on PATH), which
-- version-matches the project's GHC. We deliberately do not install HLS via
-- mason, which would ship a single build that drifts from the local toolchain.
--
-- Provides: HLS diagnostics, hlint (bundled in HLS), Hoogle type search,
-- a GHCi REPL, evaluate-in-comment code lenses, GHCi-based debugging through
-- nvim-dap (via phoityne's haskell-debug-adapter), and a ghcid reload loop.

-- ghcid: a GHCi daemon that reloads on save and streams errors/warnings (and
-- optionally re-runs an expression). It is NOT a debugger -- no breakpoints or
-- stepping -- but it is a far more robust alternative to haskell-debug-adapter
-- for the everyday save -> errors -> rerun cycle. We run it in a toggleterm
-- terminal pinned to the project root, cached per (root, command) so toggling
-- reuses the same watcher.
local ghcid_terminals = {}

--- Find the project root for ghcid (cabal/stack aware).
--- @return string
local function haskell_project_root()
  local root = vim.fs.root(0, { "cabal.project", "stack.yaml", "hie.yaml", ".git" })
  if not root then
    local matches = vim.fs.find(function(name)
      return name:match("%.cabal$")
    end, { upward = true, path = vim.api.nvim_buf_get_name(0) })
    root = matches[1] and vim.fs.dirname(matches[1]) or vim.fn.getcwd()
  end
  return root
end

--- Toggle a ghcid terminal for the current project.
--- @param extra_args string|nil extra ghcid args, e.g. "-T ':main'"
local function toggle_ghcid(extra_args)
  if vim.fn.executable("ghcid") ~= 1 then
    vim.notify(
      "ghcid not found on PATH. Install with: cabal install ghcid",
      vim.log.levels.WARN,
      { title = "haskell-tools" }
    )
    return
  end
  local ok, tt = pcall(require, "toggleterm.terminal")
  if not ok then
    vim.notify("toggleterm.nvim not available for ghcid", vim.log.levels.WARN, { title = "haskell-tools" })
    return
  end

  local root = haskell_project_root()
  local cmd = extra_args and ("ghcid " .. extra_args) or "ghcid"
  local key = root .. "|" .. cmd
  local term = ghcid_terminals[key]
  if not term then
    term = tt.Terminal:new({
      cmd = cmd,
      dir = root,
      direction = "horizontal",
      close_on_exit = false,
      hidden = true,
    })
    ghcid_terminals[key] = term
  end
  term:toggle()
end

-- Reading dependency source (A). HLS 2.14 cannot go-to-definition into
-- dependencies (upstream #708: it never indexes their .hie), so instead we
-- unpack a package's source with `cabal get` into a stable cache dir and open it
-- in the picker. Within an unpacked package you get full navigation; across your
-- project you at least get to read the library. `:HsDep aeson` or a version pin
-- `:HsDep aeson-2.2.5.0`. (Hackage packages only -- git/source-repo deps aren't
-- fetched by `cabal get`.)
local hls_deps_dir = vim.fn.expand("~/.cache/hls-deps")

-- Reading dependency source (C) + fast local navigation: fast-tags/ctags.
-- HLS `gd` handles local definitions and `:HsDep`/Hoogle handle libraries, but
-- HLS still cannot `gd` into dependencies (upstream #708). fast-tags fills the
-- gap: once tags exist, Ctrl-] jumps instantly to anything it indexed -- across
-- the whole project, and (via :HsTagsDeps) into unpacked dependency sources too
-- -- with no language server involved.
--
-- Where tags live: Neovim's cache dir, keyed per project root. NOT the project
-- (keeps the repo clean, no .gitignore churn) and NOT the hls-deps source cache
-- (that dir is transient). We point buffer-local &tags at absolute paths so
-- Ctrl-] works regardless of :cd. Generation is delegated to the shell script
-- scripts/haskell-tags.sh (single source of truth; also runnable by hand).
local tags_dir = vim.fn.stdpath("cache") .. "/haskell-tags"
local tags_script = vim.fn.stdpath("config") .. "/scripts/haskell-tags.sh"
local deps_tags_file = tags_dir .. "/deps.tags"
local tags_generated = {} -- root -> true; auto-generate at most once per session

local function project_tags_file(root)
  return tags_dir .. "/" .. root:gsub("[/\\:]", "%%") .. ".tags"
end

--- Run the tags script (via bash, so it works regardless of the exec bit).
local function run_tags_script(args, on_done)
  local cmd = { "bash", tags_script }
  vim.list_extend(cmd, args)
  vim.system(cmd, { text = true }, function(res)
    if on_done then
      vim.schedule(function()
        on_done(res)
      end)
    end
  end)
end

-- Guard so we only ever launch one background `cabal install fast-tags`.
local fast_tags_installing = false

--- Ensure fast-tags is available. If it is, run `on_ready` now. If not, kick
--- off a one-time background install and run `on_ready` once it succeeds. This
--- is what makes tags "just appear" when you open a Haskell project on a fresh
--- machine: HLS attaches -> we install fast-tags if needed -> we generate.
local function ensure_fast_tags(on_ready)
  if vim.fn.executable("fast-tags") == 1 then
    if on_ready then on_ready() end
    return true
  end
  if fast_tags_installing then
    return false
  end
  fast_tags_installing = true
  vim.notify("fast-tags not found -- installing via cabal (one-time)...", vim.log.levels.INFO, { title = "haskell-tags" })
  run_tags_script({ "--install" }, function(res)
    fast_tags_installing = false
    if res.code == 0 then
      vim.notify("fast-tags installed.", vim.log.levels.INFO, { title = "haskell-tags" })
      if on_ready then on_ready() end
    else
      vim.notify(
        "fast-tags install failed:\n" .. ((res.stderr or "") ~= "" and res.stderr or res.stdout or ""),
        vim.log.levels.ERROR,
        { title = "haskell-tags" }
      )
    end
  end)
  return false
end

--- (Re)generate the ctags index for a project (installing fast-tags first if
--- needed). Runs in the background; only notifies when `opts.notify` is set.
local function generate_project_tags(root, opts)
  opts = opts or {}
  vim.fn.mkdir(tags_dir, "p")
  local out = project_tags_file(root)
  ensure_fast_tags(function()
    if opts.notify then
      vim.notify("Generating Haskell tags for " .. vim.fn.fnamemodify(root, ":t") .. "...", vim.log.levels.INFO, { title = "haskell-tags" })
    end
    run_tags_script({ "--out", out, root }, function(res)
      if res.code ~= 0 then
        vim.notify(
          "fast-tags failed:\n" .. ((res.stderr or "") ~= "" and res.stderr or res.stdout or ""),
          vim.log.levels.ERROR,
          { title = "haskell-tags" }
        )
      elseif opts.notify then
        vim.notify("Haskell tags ready (Ctrl-] to jump).", vim.log.levels.INFO, { title = "haskell-tags" })
      end
    end)
  end)
end

--- Index the unpacked dependency sources (the :HsDep cache) into deps.tags, so
--- Ctrl-] jumps into library code HLS can't navigate. Populate the cache first
--- with `:HsDep <pkg>`.
local function generate_deps_tags()
  if vim.fn.isdirectory(hls_deps_dir) ~= 1 then
    vim.notify("No unpacked dependencies yet -- use :HsDep <pkg> first.", vim.log.levels.WARN, { title = "haskell-tags" })
    return
  end
  vim.fn.mkdir(tags_dir, "p")
  ensure_fast_tags(function()
    vim.notify("Indexing dependency sources...", vim.log.levels.INFO, { title = "haskell-tags" })
    run_tags_script({ "--deps", hls_deps_dir, "--out", deps_tags_file }, function(res)
      if res.code ~= 0 then
        vim.notify(
          "fast-tags (deps) failed:\n" .. ((res.stderr or "") ~= "" and res.stderr or res.stdout or ""),
          vim.log.levels.ERROR,
          { title = "haskell-tags" }
        )
      else
        vim.notify("Dependency tags ready.", vim.log.levels.INFO, { title = "haskell-tags" })
      end
    end)
  end)
end

--- Incremental single-file update, run on save. Cheap (one file), and never
--- triggers an install -- if there's no base index or no fast-tags yet, skip.
local function update_file_tags(root, file)
  if vim.fn.executable("fast-tags") ~= 1 then
    return
  end
  local out = project_tags_file(root)
  if vim.fn.filereadable(out) ~= 1 then
    return
  end
  run_tags_script({ "--update", file, "--out", out })
end

--- Point buffer-local &tags at our cache files (absolute, so Ctrl-] is
--- cwd-independent), keeping the default upward `./tags` search as a fallback.
local function set_buffer_tags(root)
  vim.opt_local.tags = { project_tags_file(root), deps_tags_file, "./tags", "tags" }
end

--- Generate (or refresh) the local Hoogle database, so Hoogle search works
--- offline via telescope-hoogle / haskell-tools (mode = "auto").
local function generate_hoogle_db()
  if vim.fn.executable("hoogle") ~= 1 then
    vim.notify("hoogle not found. Install with: cabal install hoogle", vim.log.levels.WARN, { title = "hoogle" })
    return
  end
  vim.notify("Generating local Hoogle database...", vim.log.levels.INFO, { title = "hoogle" })
  vim.system({ "hoogle", "generate" }, { text = true }, function(res)
    vim.schedule(function()
      if res.code == 0 then
        vim.notify("Local Hoogle database ready.", vim.log.levels.INFO, { title = "hoogle" })
      else
        vim.notify(
          "hoogle generate failed:\n" .. ((res.stderr or "") ~= "" and res.stderr or res.stdout or ""),
          vim.log.levels.ERROR,
          { title = "hoogle" }
        )
      end
    end)
  end)
end

--- Tier-3 `gd` fallback (see lua/alex/lib/goto.lua): when HLS has no definition
--- and ctags has no entry, the symbol usually lives in a dependency whose source
--- isn't indexed. Search Hoogle for it and open its Haddock/Hackage docs page in
--- the browser -- you can at least read the API. Uses the local Hoogle DB if
--- generated (offline), else Hoogle's bundled default; either way each hit
--- carries a `url` to the rendered docs.
local function hoogle_open_docs(word)
  word = word or vim.fn.expand("<cword>")
  if word == "" then
    return
  end
  if vim.fn.executable("hoogle") ~= 1 then
    vim.notify(
      "hoogle not found (cabal install hoogle) -- can't look up '" .. word .. "'",
      vim.log.levels.WARN,
      { title = "goto" }
    )
    return
  end
  vim.system({ "hoogle", "--json", "--count=15", word }, { text = true }, function(res)
    vim.schedule(function()
      local items = {}
      if res.code == 0 and res.stdout and res.stdout ~= "" then
        local ok, data = pcall(vim.json.decode, res.stdout)
        if ok and type(data) == "table" then
          items = data
        end
      end
      -- Keep only results that actually link to a docs page.
      items = vim.tbl_filter(function(it)
        return type(it) == "table" and type(it.url) == "string" and it.url ~= ""
      end, items)

      if vim.tbl_isempty(items) then
        vim.notify("Hoogle found no docs for '" .. word .. "'", vim.log.levels.WARN, { title = "goto" })
        return
      end
      if #items == 1 then
        vim.ui.open(items[1].url)
        return
      end
      -- Several matches (overloads / re-exports): let the user pick which docs.
      vim.ui.select(items, {
        prompt = "Hoogle docs for '" .. word .. "':",
        format_item = function(it)
          local pkg = (it.package and it.package.name) or ""
          local mod = (it.module and it.module.name) or ""
          local label = (it.item or ""):gsub("<%/?%a+.->", "") -- strip HTML tags
          local loc = ""
          if pkg ~= "" or mod ~= "" then
            loc = "  [" .. pkg .. (mod ~= "" and (" " .. mod) or "") .. "]"
          end
          return (label ~= "" and label or (pkg .. " " .. mod)) .. loc
        end,
      }, function(choice)
        if choice then
          vim.ui.open(choice.url)
        end
      end)
    end)
  end)
end

local function open_dir_in_picker(dir)
  local title = "Dep: " .. vim.fn.fnamemodify(dir, ":t")
  if _G.Snacks and Snacks.picker then
    Snacks.picker.files({ cwd = dir, title = title })
  else
    local ok, tb = pcall(require, "telescope.builtin")
    if ok then
      tb.find_files({ cwd = dir, prompt_title = title })
    else
      vim.cmd("edit " .. vim.fn.fnameescape(dir))
    end
  end
end

--- Unpack a Haskell dependency's source and browse it.
--- @param pkg string|nil package name, optionally version-pinned (pkg-x.y.z)
local function haskell_browse_dep(pkg)
  if not pkg or pkg == "" then
    pkg = vim.fn.input("Browse dependency source (pkg or pkg-version): ")
  end
  if pkg == "" then
    return
  end
  vim.fn.mkdir(hls_deps_dir, "p")
  -- Already unpacked? Just open it.
  for _, d in ipairs(vim.fn.glob(hls_deps_dir .. "/" .. pkg .. "*", true, true)) do
    if vim.fn.isdirectory(d) == 1 then
      open_dir_in_picker(d)
      return
    end
  end
  if vim.fn.executable("cabal") ~= 1 then
    vim.notify("cabal not found on PATH", vim.log.levels.ERROR, { title = "HsDep" })
    return
  end
  vim.notify("Unpacking " .. pkg .. " ...", vim.log.levels.INFO, { title = "HsDep" })
  vim.system(
    { "cabal", "get", pkg, "--destdir=" .. hls_deps_dir },
    { text = true },
    function(res)
      vim.schedule(function()
        if res.code ~= 0 then
          vim.notify(
            "cabal get " .. pkg .. " failed:\n" .. ((res.stderr or "") ~= "" and res.stderr or res.stdout or ""),
            vim.log.levels.ERROR,
            { title = "HsDep" }
          )
          return
        end
        local target
        for _, d in ipairs(vim.fn.glob(hls_deps_dir .. "/" .. pkg .. "*", true, true)) do
          if vim.fn.isdirectory(d) == 1 then
            target = d
          end
        end
        if target then
          open_dir_in_picker(target)
        else
          vim.notify("Unpacked, but couldn't locate the source dir for " .. pkg, vim.log.levels.WARN, { title = "HsDep" })
        end
      end)
    end
  )
end

return {
  "mrcjkb/haskell-tools.nvim",
  version = "^10",
  ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
  dependencies = {
    -- DAP: haskell-tools drives phoityne's haskell-debug-adapter through
    -- nvim-dap. dap-ui mirrors the Rust setup in plugin-rust.lua.
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    -- ghcid runs in a toggleterm terminal (see toggle_ghcid above).
    "akinsho/toggleterm.nvim",
  },
  init = function()
    -- haskell-tools has no setup() — it reads vim.g.haskell_tools on load.
    vim.g.haskell_tools = {
      tools = {
        -- Prefer telescope for Hoogle results when available, else fall back
        -- to the web backend (no local Hoogle DB required).
        hoogle = { mode = "auto" },
        hover = { auto_focus = false },
      },
      hls = {
        -- capabilities are auto-detected from cmp_nvim_lsp / blink.cmp.
        default_settings = {
          haskell = {
            -- Match the formatter used by conform (ormolu is installed).
            formattingProvider = "ormolu",
            cabalFormattingProvider = "cabalfmt",
            -- hlint is bundled with HLS; keep its diagnostics + code actions.
            plugin = {
              hlint = { globalOn = true },
            },
          },
        },
        on_attach = function(_, bufnr, ht)
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
          end

          -- HLS relies heavily on code lenses (eval, add type sig, etc.)
          map("n", "<leader>cl", vim.lsp.codelens.run, "Haskell: run code lens")
          map("n", "<leader>ea", ht.lsp.buf_eval_all, "Haskell: eval all snippets")

          -- Reading libraries (B): HLS can't jump into dependencies (upstream
          -- #708), so lean on hover + Hoogle for their APIs, and <leader>hd to
          -- pull up a dependency's actual source (see :HsDep).
          -- K: hover shows the type + haddock for the symbol under the cursor.
          map("n", "K", vim.lsp.buf.hover, "Haskell: hover (type + docs)")
          -- Hoogle search for the symbol under the cursor
          map("n", "<leader>hs", ht.hoogle.hoogle_signature, "Haskell: Hoogle signature")
          -- Hoogle picker (telescope-hoogle); uses the local DB if generated,
          -- else the web backend. <leader>hg (re)builds the local DB.
          map("n", "<leader>hh", "<cmd>Telescope hoogle<cr>", "Haskell: Hoogle search (Telescope)")
          map("n", "<leader>hg", generate_hoogle_db, "Haskell: generate local Hoogle DB")
          -- Open the symbol's Haddock docs in the browser (also `gd`'s last
          -- resort, after LSP + ctags).
          map("n", "<leader>ho", function()
            hoogle_open_docs()
          end, "Haskell: open Hoogle/Haddock docs (browser)")
          -- Browse a dependency's unpacked source (A)
          map("n", "<leader>hd", function()
            haskell_browse_dep()
          end, "Haskell: browse a dependency's source (:HsDep)")

          -- ctags (C): Ctrl-] to jump. Point &tags at our cache and, on the
          -- first Haskell buffer of each project this session, auto-generate
          -- the index in the background (installing fast-tags if missing).
          local tags_root = haskell_project_root()
          set_buffer_tags(tags_root)
          if not tags_generated[tags_root] then
            tags_generated[tags_root] = true
            if vim.fn.filereadable(project_tags_file(tags_root)) ~= 1 then
              generate_project_tags(tags_root)
            end
          end
          -- Manual (re)generation: <leader>ht project, <leader>hT deps.
          map("n", "<leader>ht", function()
            generate_project_tags(haskell_project_root(), { notify = true })
          end, "Haskell: (re)generate project tags")
          map("n", "<leader>hT", generate_deps_tags, "Haskell: index dependency sources for tags")

          -- GHCi REPL
          map("n", "<leader>rr", ht.repl.toggle, "Haskell: toggle package REPL")
          map("n", "<leader>rf", function()
            ht.repl.toggle(vim.api.nvim_buf_get_name(0))
          end, "Haskell: toggle buffer REPL")
          map("n", "<leader>rq", ht.repl.quit, "Haskell: quit REPL")

          -- ghcid: fast reload/error loop (robust alternative to DAP).
          -- <leader>rg watches for errors; <leader>rG also re-runs :main.
          map("n", "<leader>rg", function()
            toggle_ghcid()
          end, "Haskell: toggle ghcid (reload loop)")
          map("n", "<leader>rG", function()
            toggle_ghcid("-T ':main'")
          end, "Haskell: toggle ghcid + run :main on reload")

          -- Debugging (nvim-dap). haskell-tools generates launch configs from
          -- the cabal/stack project; <leader>dd discovers them, then the
          -- shared dap keymaps (<leader>dc/dt/du) drive the session.
          map("n", "<leader>dd", function()
            ht.dap.discover_configurations(bufnr)
          end, "Haskell: discover DAP configurations")
        end,
      },
      -- Only advertise the debug adapter when its binary is present, so a
      -- machine without haskell-debug-adapter simply has no Haskell DAP
      -- rather than a broken adapter. Install with:
      --   cabal install haskell-debug-adapter ghci-dap
      dap = vim.fn.executable("haskell-debug-adapter") == 1
          and {
            cmd = { "haskell-debug-adapter" },
            logLevel = "Warning",
            auto_discover = true,
          }
        or nil,
    }
  end,
  config = function()
    -- A: `:HsDep <pkg>` unpacks a dependency's source and opens it in the picker
    -- (reliable way to read library code, since HLS can't `gd` into deps).
    vim.api.nvim_create_user_command("HsDep", function(o)
      haskell_browse_dep(o.args)
    end, { nargs = "?", desc = "Haskell: unpack & browse a dependency's source (reads library code)" })

    -- C: ctags via fast-tags. :HsTags (re)indexes the project, :HsTagsDeps
    -- indexes the :HsDep source cache, :HsTagsInstall installs fast-tags, and
    -- :HsHoogleGenerate builds the local Hoogle DB.
    vim.api.nvim_create_user_command("HsTags", function()
      generate_project_tags(haskell_project_root(), { notify = true })
    end, { desc = "Haskell: (re)generate project ctags (fast-tags)" })
    vim.api.nvim_create_user_command("HsTagsDeps", function()
      generate_deps_tags()
    end, { desc = "Haskell: index unpacked dependency sources for ctags" })
    vim.api.nvim_create_user_command("HsTagsInstall", function()
      ensure_fast_tags()
    end, { desc = "Haskell: install fast-tags (cabal)" })
    vim.api.nvim_create_user_command("HsHoogleGenerate", function()
      generate_hoogle_db()
    end, { desc = "Haskell: generate the local Hoogle database" })

    -- Tier-3 `gd` fallback: when LSP and ctags both miss, open the symbol's
    -- Haddock docs via Hoogle (see lua/alex/lib/goto.lua). Also on demand:
    -- :HsDocs [symbol] / <leader>ho.
    require("alex.lib.goto").register_doc_fallback({ "haskell", "lhaskell" }, hoogle_open_docs)
    vim.api.nvim_create_user_command("HsDocs", function(o)
      hoogle_open_docs(o.args ~= "" and o.args or nil)
    end, { nargs = "?", desc = "Haskell: open a symbol's Haddock docs via Hoogle (browser)" })

    -- Keep the project index fresh: after saving a Haskell file, merge just
    -- that file's tags back in (cheap; skips if there's no base index yet).
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = vim.api.nvim_create_augroup("HaskellTagsUpdate", { clear = true }),
      pattern = { "*.hs", "*.lhs" },
      callback = function(args)
        update_file_tags(haskell_project_root(), args.file)
      end,
    })

    -- Work around an upstream haskell-tools bug (v10.0.1): its ftplugin fires
    -- for ANY buffer that gets filetype=haskell -- including transient buffers
    -- like picker preview buffers -- and starts HLS on them. HLS's on_init
    -- callback runs asynchronously and captures that buffer number; if the
    -- buffer is wiped before on_init fires, it throws
    --   ON_INIT_CALLBACK_ERROR ... lsp/init.lua:24: Invalid buffer id
    -- The plugin doesn't expose on_init, so we guard lsp.start instead: only
    -- attach HLS to real, on-disk file buffers (buftype == ""). The lazy_require
    -- proxy delegates to this same module table, so the ftplugin sees the wrap.
    local lsp = require("haskell-tools.lsp")
    if not lsp._buftype_guard_installed then
      local orig_start = lsp.start
      lsp.start = function(bufnr)
        bufnr = bufnr or vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_is_valid(bufnr)
          and vim.bo[bufnr].buftype == ""
          and vim.api.nvim_buf_get_name(bufnr) ~= ""
        then
          return orig_start(bufnr)
        end
      end
      lsp._buftype_guard_installed = true
    end

    -- Shared nvim-dap-ui setup (guarded so it runs once even though
    -- plugin-rust.lua also initialises dap-ui).
    if not vim.g._dapui_configured then
      require("dapui").setup()
      vim.g._dapui_configured = true
    end

    -- Shared DAP keymaps (match the ones in plugin-rust.lua).
    local dap = require("dap")
    vim.keymap.set("n", "<leader>du", require("dapui").toggle, { desc = "DAP: toggle UI" })
    vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP: continue" })
    vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint, { desc = "DAP: toggle breakpoint" })

    if vim.fn.executable("haskell-debug-adapter") ~= 1 then
      vim.notify(
        "haskell-debug-adapter not found; Haskell debugging is disabled.\n"
          .. "Install it with: cabal install haskell-debug-adapter ghci-dap",
        vim.log.levels.WARN,
        { title = "haskell-tools" }
      )
    end
  end,
}
