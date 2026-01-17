# Niri Configuration

## Good to know

After installing, start niri from your display manager like GDM. Press Super+T to run a terminal (Alacritty) and Super+D to run an application launcher (fuzzel). To exit niri, press Super+Shift+E.

## VRAM Usage

Presently, there is a quirk in the NVIDIA drivers that affects niri's VRAM usage (the driver does not properly release VRAM back into the pool). Niri should use on the order of 100 MiB of VRAM (as checked in nvtop); if you see anywhere close to 1 GiB of VRAM in use, you are likely hitting this issue (heap not returning freed buffers to the driver).

Luckily, you can mitigate this by configuring the NVIDIA drivers with a per-process application profile as follows:

sudo mkdir -p /etc/nvidia/nvidia-application-profiles-rc.d to make the config dir if it does not exist (it most likely does not if you are reading this)
write the following JSON blob to set the GLVidHeapReuseRatio config value for the niri process into the file /etc/nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json:

```

{
    "rules": [
        {
            "pattern": {
                "feature": "procname",
                "matches": "niri"
            },
            "profile": "Limit Free Buffer Pool On Wayland Compositors"
        }
    ],
    "profiles": [
        {
            "name": "Limit Free Buffer Pool On Wayland Compositors",
            "settings": [
                {
                    "key": "GLVidHeapReuseRatio",
                    "value": 0
                }
            ]
        }
    ]
}

```

(The file in /etc/nvidia/nvidia-application-profiles-rc.d/ can be named anything, and does not actually need an extension).
