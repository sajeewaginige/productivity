# mac — Window Layout CLI

Organize macOS windows across multiple displays during development work.

## Commands

| Command | Description |
|---------|-------------|
| `mac window setup dev` | Tile VS Code, browsers, and terminals across 3 displays |
| `mac w s dev` | Short form |
| `mac window sweep [n]` | Sweep all apps onto one display (see [README.md](README.md)) |
| `mac w sw [n]` | Short form |

## `mac window setup dev`

Assigns application groups to dedicated displays and tiles windows edge-to-edge.

### Display assignment

| Group | Applications | Default display |
|-------|-------------|-----------------|
| **VS Code** | `Code`, `Code - Insiders` | Display 1 |
| **Browsers** | Chrome, Safari, Firefox, Arc, Brave, Edge, Chromium, Orion, Vivaldi | Display 2 |
| **Terminals** | Terminal, iTerm2, Warp, Alacritty, kitty, WezTerm, Hyper | Display 3 |

### VS Code tiling

Windows are docked to fill the display with minimal gaps:

| Open windows | Layout |
|-------------|--------|
| 1 | Full screen |
| 2–3 | Equal-width columns (side by side) |
| 4–6 | 3×2 grid |
| 7–12 | 4×3 grid |
| 13–24 | 4×6 grid |
| 25+ | 4-column grid, rows expand as needed |

Browsers and terminals use the same adaptive grid on their assigned display.

### Rotation

Each time you run `mac window setup dev`, the three groups **rotate** across displays:

```
Run 1: VS Code → 1, Browsers → 2, Terminals → 3
Run 2: VS Code → 2, Browsers → 3, Terminals → 1
Run 3: VS Code → 3, Browsers → 1, Terminals → 2
Run 4: back to Run 1 layout
```

Rotation state is stored in `~/.kodez/setup-dev-state.json`.

### Example output

```
rotation 0 | VS Code -> display 1, Browsers -> display 2, Terminals -> display 3 | tiled: vscode=3, browser=2, terminal=1
```

## `mac window sweep`

Moves all visible windows onto a single display in a 4×3 app grid.

```bash
mac window sweep           # display 1
mac w sw 2                 # display 2
mac window sweep --refresh # rebuild screen cache first
```

## Installation

Run the install script from the source directory:

```bash
cd ~/projects/productivity/scripts
./install.sh
```

Options:

```bash
./install.sh --warm-cache    # also build display cache on install
./install.sh --kodez-dir ~/.kodez
./install.sh --no-path       # skip shell rc PATH update
```

The installer will:

- Verify macOS, Bash, Python 3, and `osascript` are available
- Set executable permissions on all scripts
- Install the `mac` wrapper to `~/.kodez/`
- Add `~/.kodez` to your shell PATH (`.zshrc` or `.bash_profile`)
- **Prompt for Accessibility permission** — shows a dialog, triggers the macOS permission request, and opens **System Settings → Privacy & Security → Accessibility**

Without Accessibility, `mac window setup dev` will report `tiled: vscode=0, browser=0, terminal=0` and windows will not move.

```bash
./install.sh --skip-accessibility   # non-interactive / skip the prompt
```

## Requirements

- macOS with 1–3+ displays (layout adapts to available screens)
- **Accessibility** permission for your terminal  
  _System Settings → Privacy & Security → Accessibility_
- Python 3 (pre-installed on macOS)

## Cache files

| File | Purpose |
|------|---------|
| `~/.kodez/screen-cache.json` | Display sizes and positions |
| `~/.kodez/setup-dev-state.json` | Rotation index for `mac window setup dev` |

Rebuild screen cache after changing monitors:

```bash
mac window setup dev --refresh
mac window sweep --refresh
```

## File layout

```
~/.kodez/
  mac          → CLI entry point

~/projects/productivity/scripts/
  mac.sh       → CLI dispatcher
  setup-dev.sh → dev layout logic (via mac window setup dev)
  sweep.sh     → single-display grid layout (via mac window sweep)
  lib/screens.sh
```