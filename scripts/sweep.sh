#!/bin/bash

# Usage:
#   mac window sweep [display_num]                  # all apps onto one display
#   mac window sweep <app> [display_num]            # one app onto one display
#   mac window sweep chrome|safari|finder|code ...  # known app aliases
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/screens.sh
source "$SCRIPT_DIR/lib/screens.sh"

DISPLAY_NUM=1
REFRESH=0
TARGET="all"

for arg in "$@"; do
    case "$arg" in
        --refresh) REFRESH=1 ;;
        [0-9]*) DISPLAY_NUM=$arg ;;
        *)
            if [[ -n "$arg" ]]; then
                TARGET="$arg"
            fi
            ;;
    esac
done

load_screen_cache
read -r TARGET_X TARGET_Y SCREEN_W SCREEN_H < <(get_screen_dims "$DISPLAY_NUM")

if [[ "$TARGET" != "all" ]]; then
    RESULT=$(osascript "$SCRIPT_DIR/lib/sweep-app.applescript" \
        "$TARGET" "$TARGET_X" "$TARGET_Y" "$SCREEN_W" "$SCREEN_H")
    echo "$RESULT"
    exit 0
fi

osascript - "$TARGET_X" "$TARGET_Y" "$SCREEN_W" "$SCREEN_H" <<'APPLESCRIPT'
on run argv
    set targetX to item 1 of argv as integer
    set targetY to item 2 of argv as integer
    set screenWidth to item 3 of argv as integer
    set screenHeight to item 4 of argv as integer

    set gridCols to 4
    set gridRows to 3
    set gridCells to gridCols * gridRows
    set edgeMargin to 24
    set cellPadding to 10
    set windowCascade to 18
    set minWindowW to 180
    set minWindowH to 100

    set availableW to screenWidth - (edgeMargin * 2)
    set availableH to screenHeight - (edgeMargin * 2)
    set cellW to availableW div gridCols
    set cellH to availableH div gridRows

    tell application "System Events"
        set appIndex to 0

        repeat with thisProcess in (every application process)
            try
                set visibleWindows to {}
                repeat with thisWindow in (every window of thisProcess)
                    try
                        if value of attribute "AXMinimized" of thisWindow is false then
                            set end of visibleWindows to thisWindow
                        end if
                    end try
                end repeat

                if (count of visibleWindows) > 0 then
                    my layoutAppInGrid(visibleWindows, appIndex, targetX, targetY, cellW, cellH, gridCols, gridRows, gridCells, edgeMargin, cellPadding, windowCascade, minWindowW, minWindowH)
                    set appIndex to appIndex + 1
                end if
            end try
        end repeat
    end tell
end run

on layoutAppInGrid(visibleWindows, appIndex, targetX, targetY, cellW, cellH, gridCols, gridRows, gridCells, edgeMargin, cellPadding, windowCascade, minWindowW, minWindowH)
    set winCount to count of visibleWindows
    set gridSlot to appIndex mod gridCells
    set layer to appIndex div gridCells

    set col to gridSlot mod gridCols
    set row to gridSlot div gridCols

    set cellX to targetX + edgeMargin + (col * cellW) + (layer * 28)
    set cellY to targetY + edgeMargin + (row * cellH) + (layer * 28)

    set innerW to cellW - (cellPadding * 2)
    set innerH to cellH - (cellPadding * 2)

    set cascade to windowCascade
    set targetW to minWindowW
    set targetH to minWindowH

    repeat 10 times
        set spread to (winCount - 1) * cascade
        set targetW to innerW - spread
        set targetH to innerH - spread
        if targetW >= minWindowW and targetH >= minWindowH then exit repeat
        set cascade to cascade - 2
        if cascade < 6 then set cascade to 6
    end repeat

    if targetW < minWindowW then set targetW to minWindowW
    if targetH < minWindowH then set targetH to minWindowH

    set minX to cellX + cellPadding
    set minY to cellY + cellPadding
    set maxX to cellX + cellW - cellPadding - targetW
    set maxY to cellY + cellH - cellPadding - targetH

    if maxX < minX then set maxX to minX
    if maxY < minY then set maxY to minY

    set curX to minX
    set curY to minY
    set dx to cascade
    set dy to cascade

    repeat with thisWindow in visibleWindows
        if curX > maxX then set curX to maxX
        if curX < minX then set curX to minX
        if curY > maxY then set curY to maxY
        if curY < minY then set curY to minY

        tell application "System Events"
            set size of thisWindow to {targetW, targetH}
            set position of thisWindow to {curX, curY}
        end tell

        set nextX to curX + dx
        set nextY to curY + dy

        if nextX > maxX or nextX < minX then
            set dx to -dx
            set nextX to curX + dx
            if nextX > maxX or nextX < minX then
                set dy to -dy
                set nextY to curY + dy
                set nextX to curX
            end if
        end if

        if nextY > maxY or nextY < minY then
            set dy to -dy
            set nextY to curY + dy
            if nextY > maxY or nextY < minY then
                set dx to -dx
                set nextX to curX + dx
                set nextY to curY
            end if
        end if

        set curX to nextX
        set curY to nextY
    end repeat
end layoutAppInGrid
APPLESCRIPT