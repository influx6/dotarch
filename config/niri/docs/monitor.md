# Monitor / Display setup (niri + nwg-displays)

How to set and update display and monitor settings on this machine.

## Files

- `~/.config/niri/monitor.kdl` — the display layout, **managed by nwg-displays**
  (the GUI writes this file when you click Apply). It is loaded by this line at the
  top of `~/.config/niri/config.kdl`:

  ```kdl
  include "monitor.kdl"
  ```

- `~/.config/niri/cfg/display.kdl` — older stub; its `output` block is commented out
  with `/-`, so it has no effect. The real display config lives in `monitor.kdl`.

## Current layout

| Display             | Connector | Mode                      | Scale | Position          |
|---------------------|-----------|---------------------------|-------|-------------------|
| Laptop panel        | `eDP-1`   | 1920x1080 @ 144.000 Hz    | 1     | x=0, y=0 (left)   |
| External (Acer KA272U) | `DP-1`  | 2560x1440 @ 59.951 Hz     | 1     | x=1920, y=0 (right) |

## Using the GUI (recommended)

1. Launch it:
   - App launcher → search **nwg-displays**, or
   - Terminal: `nwg-displays`
2. Drag the display rectangles to set their relative arrangement.
3. Click a display to set its:
   - **Mode / refresh rate** (resolution + Hz)
   - **Scale** (1 = no scaling, 2 = 2× for HiDPI)
   - **Rotation / transform**
   - **Adaptive sync (VRR)** — only meaningful on displays that support it
     (the laptop panel does; the Acer does not)
4. Click **Apply**. nwg-displays writes `monitor.kdl` and hot-reloads niri, so the
   change takes effect immediately.
5. To disable a display, uncheck it — nwg-displays writes `off` for it.

## CLI (no GUI)

- List connected outputs and their exact names/modes:

  ```
  niri msg outputs
  ```

- Validate the config before/after editing:

  ```
  niri validate
  ```

- Reload config to apply manual edits:

  ```
  niri msg action load-config-file
  ```

## Editing `monitor.kdl` by hand

Each output is a block:

```kdl
output "DP-1" {
    mode "2560x1440@59.951"
    scale 1
    position x=1920 y=0
}
```

Key points:

- Output names come from `niri msg outputs` (`DP-1`, `eDP-1`, …).
- The refresh rate in `mode` must match `niri msg outputs` **exactly** (to three
  decimals), e.g. `59.951`, `144.000`.
- `position x=<x> y=<y>` places the output; without it niri auto-places outputs.
- `variable-refresh-rate` enables VRR on displays that support it.
- `off` disables an output.

After editing: run `niri validate`, then `niri msg action load-config-file`.

## Notes

- nwg-displays overwrites `monitor.kdl` wholesale on Apply, so manual edits there are
  lost. Prefer editing through the GUI; fall back to hand-editing only when needed.
- The "Do not edit manually" header nwg-displays writes is just its convention —
  hand-editing still works and is checked by `niri validate`.
