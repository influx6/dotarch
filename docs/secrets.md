# Encrypted secrets (git-agecrypt + age + 1Password)

Files under `secrets/` are **plaintext in your working tree** and **age-ciphertext
in the git blobs** — encrypted automatically on commit, decrypted automatically
on checkout, via git's clean/smudge filters (same model as git-crypt).

The age **private key never lives in the repo**. It is stored in **1Password**;
`secrets unlock` fetches it into a `0600` file outside the repo for the session,
`secrets lock` shreds it. The age **public key** (recipient) is committed in
`git-agecrypt.toml`, so *encryption* needs no secret at all.

Tooling: `age`, `op` (1Password CLI) and `git-agecrypt` — install via
`installers/every/git-agecrypt.sh`. Day-to-day commands live in `bin/secrets`
(on `PATH` as `secrets`).

---

## One-time bootstrap

```bash
# 0. tools + 1Password CLI signed in (desktop app: Settings -> Developer ->
#    "Integrate with 1Password CLI")
bash installers/every/git-agecrypt.sh
op signin && op whoami

# 1. generate an age key (keep the printed public key)
age-keygen -o /tmp/dotarch-age.txt          # public key printed to stderr
PRIV=$(grep AGE-SECRET-KEY /tmp/dotarch-age.txt)
PUB=$(grep -oE 'age1[0-9a-z]+' /tmp/dotarch-age.txt | head -1)

# 2. store it in 1Password as item "dotarch-age" (fields privatekey/publickey)
op item create --category "Secure Note" --vault Private --title dotarch-age \
  "privatekey[password]=$PRIV" "publickey[text]=$PUB"
shred -u /tmp/dotarch-age.txt                # remove the on-disk copy

# 3. wire up the repo (run in the dotarch repo root)
git-agecrypt init                            # writes clean/smudge/diff to .git/config
# repo-ROOT .gitattributes (a secrets/** pattern inside secrets/.gitattributes
# would not match — subdir patterns are relative to that subdir)
printf 'secrets/** filter=git-agecrypt diff=git-agecrypt\n' >> .gitattributes
secrets unlock                               # materialise key + set identity (.git/config)

# 4. add your first secret
mkdir -p secrets
printf 'API_TOKEN=...\n' > secrets/example.env
secrets add secrets/example.env              # registers recipient in git-agecrypt.toml
git add secrets/.gitattributes git-agecrypt.toml secrets/example.env
git commit -m "ADD: first encrypted secret"

# verify the stored blob is ciphertext (should start with age-encryption.org/v1):
git cat-file blob "$(git rev-parse HEAD:secrets/example.env)" | head -1
```

> `git-agecrypt`'s `-p` requires the file to **exist**, so register each secret
> file with `secrets add <file>` before committing it.

## Daily use

- Edit files in `secrets/` like normal plaintext.
- `secrets unlock` once per session/machine (one Touch ID prompt) so checkouts
  can decrypt; `secrets lock` to wipe the local key when done.
- `secrets status` shows configured identity + recipients.

## New machine

```bash
bash installers/every/git-agecrypt.sh
op signin
git clone git@github.com:influx6/dotarch.git && cd dotarch
git-agecrypt init          # per-checkout: configures filters in .git/config
secrets unlock             # fetch key from 1Password, set identity
git checkout -- secrets/   # smudge -> plaintext
```

## Adding more secrets later

```bash
printf '...' > secrets/newthing.env
secrets add secrets/newthing.env
git add git-agecrypt.toml secrets/newthing.env && git commit -m "ADD: secret"
```

## Safety nets (optional git/GitHub hooks)

git-agecrypt handles encrypt/decrypt via filters — no hook required. For
defence-in-depth against ever pushing a plaintext secret:

- **Local `pre-commit` hook** — refuse to commit a `secrets/` blob that isn't
  age-encrypted:

  ```bash
  # .git/hooks/pre-commit  (or a tracked hooks dir via core.hooksPath)
  #!/bin/sh
  fail=0
  for f in $(git diff --cached --name-only --diff-filter=AM -- 'secrets/**'); do
    # the staged blob must be age ciphertext
    git cat-file blob ":$f" | head -1 | grep -q '^age-encryption.org' || {
      echo "pre-commit: $f is NOT encrypted — is git-agecrypt configured? (secrets unlock)"; fail=1; }
  done
  exit $fail
  ```

- **GitHub Action** (server-side, defence-in-depth) — scan pushed `secrets/`
  files and fail CI if any decrypts to obvious plaintext / isn't age-wrapped.
  GitHub itself only ever sees ciphertext; it can't decrypt. Keep the age key
  out of CI unless a workflow genuinely needs to decrypt.

## Notes / caveats

- The age key in `~/.config/git-agecrypt/identity` touches disk while unlocked
  (`age` has no ssh-agent support). `secrets lock` removes it. If you need
  zero-on-disk, git-crypt + `op read | git-crypt unlock -` is an alternative.
- `git-agecrypt.toml` (recipients) and `secrets/.gitattributes` are committed;
  the identity path in `.git/config` is local and never pushed.
