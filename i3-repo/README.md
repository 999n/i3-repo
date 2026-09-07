# i3 Config

My personal i3 window manager configuration.

## Structure

```
i3-repo/
├── config                  # Main i3 config → goes to ~/.config/i3/config
├── polybar/
│   └── launch.sh           # Polybar launcher → goes to ~/.config/polybar/launch.sh
└── scripts/
    ├── i3/                 # Scripts called from i3 config → go to ~/.config/i3/
    │   ├── add-to-group.sh
    │   ├── brightness-xrandr.sh
    │   ├── brightness-xrandr2.sh
    │   ├── cycle-group.sh
    │   ├── cycle-quick.sh
    │   ├── edit-window-group.sh
    │   ├── focus-mark-watcher.sh
    │   ├── gap-right.sh
    │   ├── goto-hint.sh
    │   ├── goto-mark.sh
    │   ├── group-menu.sh
    │   ├── group-next.sh
    │   ├── group-prev.sh
    │   ├── group-switch.sh
    │   ├── group-toggle.sh
    │   ├── group-toggle-window.sh
    │   ├── i3-focus-cycle.sh
    │   ├── i3-focus-tracker.sh
    │   ├── i3-title-format.sh
    │   ├── launch-and-mark.sh
    │   ├── mark-quick.sh
    │   ├── new-group.sh
    │   ├── show-focused-mark.sh
    │   ├── toggle-group-multi.sh
    │   ├── toggle-group.sh
    │   └── unmark-focused.sh
    └── bin/                # Scripts called from i3 config → go to ~/bin/
        ├── auto-mark-new-windows.sh
        ├── carousel-floats.sh
        ├── clip-daemon.sh
        ├── clip-pick.sh
        ├── cursor-jump.sh
        ├── cursor-remove.sh
        ├── deck-floats.sh
        ├── dmenu-run
        ├── float-expose.sh
        ├── float-graveyard.sh
        ├── float-hide-all.sh
        ├── float-layout-pause.sh
        ├── float-layout-watcher.py
        ├── float-peek.sh
        ├── float-pin.sh
        ├── float-record-size.sh
        ├── float-size-tracker.sh
        ├── float-trail.sh
        ├── float-zone-cycle.sh
        ├── float-zone-enforcer.sh
        ├── focus-lock.sh
        ├── fullfull.sh
        ├── i3floatarrage.sh
        ├── i3-grid-scratchpad.sh
        ├── i3-marks-rofi.sh
        ├── keynav-monitor.sh
        ├── keynav-watchdog.sh
        ├── mark-unmarked.sh
        ├── mosaic-floats.sh
        ├── personality-swap.sh
        ├── ribbon-floats.sh
        ├── rofi-exec
        ├── rofi-random.sh
        ├── rofi-random-window.sh
        ├── spotlight-floats.sh
        ├── stack-floats.sh
        ├── stale-window-marker.sh
        ├── still-floats.sh
        ├── swap-monitors.sh
        ├── tiled-expose.sh
        ├── toggle-edp1.sh
        ├── toggle-polybar.sh
        ├── window-history.sh
        ├── window-jump.sh
        ├── ws-note.sh
        ├── xcape-mark.sh
        └── zone-swap.sh
```

## Install on a new system

```bash
# Clone the repo
git clone <repo-url> ~/i3-repo
cd ~/i3-repo

# Copy i3 config
cp config ~/.config/i3/config

# Copy i3 scripts
cp scripts/i3/* ~/.config/i3/
chmod +x ~/.config/i3/*.sh

# Copy bin scripts
mkdir -p ~/bin
cp scripts/bin/* ~/bin/
chmod +x ~/bin/*

# Copy polybar launcher
cp polybar/launch.sh ~/.config/polybar/launch.sh
chmod +x ~/.config/polybar/launch.sh

# Reload i3
i3-msg restart
```

## Missing scripts

- `~/bin/toggle-hdmi2.sh` — referenced in config but not found on disk. You'll need to recreate it.
  It should toggle the HDMI2 output (similar to `toggle-edp1.sh`).

## Dependencies

- `i3` — window manager
- `picom` — compositor (binary expected at `~/bin/picom`)
- `keynav` — keyboard-driven mouse (binary expected at `~/bin/keynav`)
- `dunst` / `dunstify` — notifications
- `rofi` — application launcher
- `polybar` — status bar
- `feh` — wallpaper setter
- `xdotool` — X11 automation
- `pactl` — audio control
- `maim` — screenshots
- `xkbset` — keyboard settings
- `xbindkeys` — key bindings daemon
- `xcape` — key remapping
- `xrdb` — X resources
- `nm-applet` — network manager tray
