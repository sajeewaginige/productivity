#!/bin/bash
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "$0")" && pwd)"
KODEZ_DIR="${KODEZ_DIR:-$HOME/.kodez}"
CACHE_DIR="$KODEZ_DIR"
SHELL_RC=""

# shellcheck source=lib/accessibility.sh
source "$SCRIPT_ROOT/lib/accessibility.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}warning:${NC} $*"; }
error() { echo -e "${RED}error:${NC} $*" >&2; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Install the mac CLI tool.

Options:
  --kodez-dir DIR         Install wrappers to DIR (default: ~/.kodez)
  --no-path               Skip updating shell rc PATH
  --warm-cache            Probe displays and write screen cache after install
  --skip-accessibility    Skip Accessibility permission prompt
  -h, --help              Show this help

Environment:
  KODEZ_DIR               Same as --kodez-dir
EOF
}

SKIP_PATH=0
WARM_CACHE=0
SKIP_ACCESSIBILITY=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --kodez-dir)
            KODEZ_DIR="$2"
            CACHE_DIR="$KODEZ_DIR"
            shift 2
            ;;
        --no-path) SKIP_PATH=1; shift ;;
        --warm-cache) WARM_CACHE=1; shift ;;
        --skip-accessibility) SKIP_ACCESSIBILITY=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) error "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
    error "These scripts require macOS."
    exit 1
fi

check_dep() {
    local cmd="$1" label="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error "Missing dependency: $label ($cmd)"
        exit 1
    fi
}

info "Checking dependencies..."
check_dep bash "Bash"
check_dep python3 "Python 3"
check_dep osascript "AppleScript (macOS)"

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
info "Python $PYTHON_VERSION"

REQUIRED_SCRIPTS=(
    "$SCRIPT_ROOT/mac.sh"
    "$SCRIPT_ROOT/sweep.sh"
    "$SCRIPT_ROOT/setup-dev.sh"
    "$SCRIPT_ROOT/lib/screens.sh"
    "$SCRIPT_ROOT/lib/setup-dev-state.py"
    "$SCRIPT_ROOT/lib/setup-dev.applescript"
    "$SCRIPT_ROOT/lib/accessibility.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [[ ! -f "$script" ]]; then
        error "Missing source file: $script"
        exit 1
    fi
done

info "Setting executable permissions..."
chmod +x "$SCRIPT_ROOT/install.sh"
chmod +x "$SCRIPT_ROOT/mac.sh" "$SCRIPT_ROOT/sweep.sh" "$SCRIPT_ROOT/setup-dev.sh"
chmod +x "$SCRIPT_ROOT/lib/setup-dev-state.py"
chmod +x "$SCRIPT_ROOT/lib/accessibility.sh"

info "Installing wrappers to $KODEZ_DIR..."
mkdir -p "$KODEZ_DIR"

write_wrapper() {
    local name="$1" target="$2"
    shift 2
    cat > "$KODEZ_DIR/$name" <<EOF
#!/bin/bash
exec "$target" $* "\$@"
EOF
    chmod +x "$KODEZ_DIR/$name"
}

write_wrapper mac "$SCRIPT_ROOT/mac.sh"

# Remove legacy direct-entry wrappers (mac-only CLI going forward).
rm -f "$KODEZ_DIR/setup" "$KODEZ_DIR/reorg" "$KODEZ_DIR/reorg.sh" "$KODEZ_DIR/sweep"

pick_shell_rc() {
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        SHELL_RC="$HOME/.bashrc"
        [[ -f "$SHELL_RC" ]] || SHELL_RC="$HOME/.bash_profile"
    else
        case "$(basename "${SHELL:-}")" in
            zsh)  SHELL_RC="$HOME/.zshrc" ;;
            bash) SHELL_RC="$HOME/.bash_profile" ;;
            *)    SHELL_RC="$HOME/.profile" ;;
        esac
    fi
}

add_path_to_shell() {
    local path_line="export PATH=\"$KODEZ_DIR:\$PATH\""
    local marker="# productivity-scripts (mac)"

    pick_shell_rc
    touch "$SHELL_RC"

    if grep -Fq "$KODEZ_DIR" "$SHELL_RC" 2>/dev/null; then
        info "PATH already configured in $SHELL_RC"
        return
    fi

    {
        echo ""
        echo "$marker"
        echo "$path_line"
    } >> "$SHELL_RC"

    info "Added $KODEZ_DIR to PATH in $SHELL_RC"
    warn "Run: source $SHELL_RC   (or open a new terminal)"
}

if [[ "$SKIP_PATH" -eq 0 ]]; then
    add_path_to_shell
else
    info "Skipped shell rc PATH update (--no-path)"
fi

if [[ "$WARM_CACHE" -eq 1 ]]; then
    info "Warming screen cache..."
    # shellcheck source=lib/screens.sh
    source "$SCRIPT_ROOT/lib/screens.sh"
    REFRESH=1
    load_screen_cache
    info "Screen cache written to $CACHE_FILE"
fi

ACCESSIBILITY_OK=0
TERMINAL_APP=$(detect_terminal_app)

if [[ "$SKIP_ACCESSIBILITY" -eq 0 ]]; then
    info "Checking Accessibility permission for $TERMINAL_APP..."
    if accessibility_granted; then
        info "Accessibility permission is enabled."
        ACCESSIBILITY_OK=1
    else
        warn "Accessibility is not enabled for $TERMINAL_APP."
        info "Triggering permission prompt and opening settings..."
        PROMPT_RESULT=$(prompt_accessibility_permission || true)
        case "$PROMPT_RESULT" in
            ok)
                info "Accessibility permission is enabled."
                ACCESSIBILITY_OK=1
                ;;
            opened-settings)
                warn "Enable $TERMINAL_APP in the Accessibility list, then run:"
                warn "  mac window setup dev"
                ;;
            skipped)
                warn "Skipped Accessibility setup. Window tiling will not work until enabled."
                ;;
        esac

        if [[ "$ACCESSIBILITY_OK" -eq 0 ]] && accessibility_granted; then
            info "Accessibility permission is now enabled."
            ACCESSIBILITY_OK=1
        fi
    fi
else
    info "Skipped Accessibility setup (--skip-accessibility)"
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
cat <<EOF

  Source:    $SCRIPT_ROOT
  Wrapper:   $KODEZ_DIR/mac
  Terminal:  $TERMINAL_APP

  Commands:
    mac window setup dev   # dev layout across 3 displays (rotates each run)
    mac w s dev            # short form
    mac window sweep [n]           # sweep all apps onto display n
    mac window sweep <app> [n]     # sweep one app onto display n
    mac w sw [n]                   # short form
    mac w sw <app> [n]             # short form for single-app sweep

  Docs:
    $SCRIPT_ROOT/../README.md
    $SCRIPT_ROOT/../README-setup-mac.md

EOF

if [[ "$ACCESSIBILITY_OK" -eq 0 && "$SKIP_ACCESSIBILITY" -eq 0 ]]; then
    warn "Accessibility still disabled — run ./install.sh again after enabling $TERMINAL_APP"
fi

if [[ "$SKIP_PATH" -eq 0 ]]; then
    echo "  Ensure PATH is loaded, then run: mac window setup dev"
else
    echo "  Run with full path: $KODEZ_DIR/mac window setup dev"
fi

echo ""