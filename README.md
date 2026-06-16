# Productivity Scripts

macOS helper scripts for window and workspace management.

Install with the provided script (see [README-setup-mac.md](README-setup-mac.md) for full setup):

```bash
cd ~/projects/productivity/scripts
./install.sh
```

This checks dependencies, sets permissions, installs the `mac` CLI to `~/.kodez/`, and updates your shell PATH.

## Quick reference

| Command | What it does |
|---------|-------------|
| `mac window setup dev` | VS Code / browsers / terminals across 3 displays (rotates each run) |
| `mac w s dev` | Short form of the above |
| `mac window sweep [n]` | All apps onto one display in a 4×3 grid |
| `mac w sw [n]` | Short form |

## `mac window sweep`

Moves all visible (non-minimized) application windows onto a chosen display and arranges them in a tidy grid.

### What it does

- Targets a display by number (`1` = primary, `2` = second, etc.)
- Groups windows by application — each app gets its own grid cell
- Lays out apps on a **4×3 grid** (4 columns, 3 rows = 12 cells)
- Resizes windows to fit their cell, then stacks them with a small cascade offset
- If a stack hits the cell edge, placement reverses direction so windows stay inside the cell
- Caches screen sizes in `~/.kodez/screen-cache.json` for faster repeat runs

### Usage

```bash
mac window sweep       # display 1
mac w sw 2             # display 2
mac window sweep --refresh
```

### Notes

- Minimized windows are left unchanged
- More than 12 apps reuse grid cells with a slight offset
- Re-run with `--refresh` after connecting or disconnecting monitors

## `mac window setup dev`

See **[README-setup-mac.md](README-setup-mac.md)** for dev layout details, rotation behaviour, and supported applications.

## Requirements

- macOS
- **Accessibility** permission for the terminal running the scripts  
  _System Settings → Privacy & Security → Accessibility_