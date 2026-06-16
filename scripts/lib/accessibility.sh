#!/bin/bash
# Helpers for macOS Accessibility permission checks and prompts.

detect_terminal_app() {
    if [[ -n "${TERM_PROGRAM:-}" ]]; then
        case "$TERM_PROGRAM" in
            Apple_Terminal) echo "Terminal" ;;
            iTerm.app)      echo "iTerm" ;;
            WarpTerminal)   echo "Warp" ;;
            vscode)         echo "Code" ;;
            *)              echo "$TERM_PROGRAM" ;;
        esac
        return 0
    fi

    local pid=$PPID
    local name
    for _ in 1 2 3 4 5 6; do
        name=$(ps -o comm= -p "$pid" 2>/dev/null | xargs basename 2>/dev/null)
        case "$name" in
            Terminal|iTerm2|Warp|Code|Cursor|kitty|Alacritty|WezTerm|Hyper)
                echo "$name"
                return 0
                ;;
        esac
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | xargs)
        [[ -z "$pid" || "$pid" -eq 1 ]] && break
    done

    echo "your terminal app"
}

accessibility_granted() {
    osascript <<'APPLESCRIPT' >/dev/null 2>&1
tell application "System Events"
    tell process "Finder"
        get count of windows
    end tell
end tell
APPLESCRIPT
}

open_accessibility_settings() {
    # Ventura / Sonoma / Sequoia
    if open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility" 2>/dev/null; then
        return 0
    fi
    # Older macOS fallback
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null
}

trigger_accessibility_prompt() {
    # Attempting UI scripting usually triggers the macOS permission dialog.
    osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
tell application "System Events"
    tell process "Finder"
        get count of windows
    end tell
end tell
APPLESCRIPT
}

prompt_accessibility_permission() {
    local terminal_app
    terminal_app=$(detect_terminal_app)

    if accessibility_granted; then
        echo "ok"
        return 0
    fi

    trigger_accessibility_prompt

    local choice
    choice=$(osascript <<EOF 2>/dev/null || echo "Later"
set terminalApp to "$terminal_app"
try
    display dialog "mac needs Accessibility permission for " & terminalApp & ".

Without this, window tiling will not work (you will see tiled: vscode=0, browser=0, terminal=0).

Steps:
1. Click Open Settings below
2. Enable the toggle for " & terminalApp & "
3. Run: mac window setup dev" buttons {"Open Settings", "Later"} default button 1 with title "Accessibility Required" giving up after 120
    return button returned of result
on error
    return "Later"
end try
EOF
)

    if [[ "$choice" == "Open Settings" ]]; then
        open_accessibility_settings
        echo "opened-settings"
    else
        echo "skipped"
    fi

    return 1
}