#!/bin/bash

# Dev workspace layout across 3 displays with rotating group assignments.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/screens.sh
source "$SCRIPT_DIR/lib/screens.sh"

STATE_FILE="$CACHE_DIR/setup-dev-state.json"
REFRESH=0
DEBUG=0

for arg in "$@"; do
    case "$arg" in
        --refresh) REFRESH=1 ;;
        --debug) DEBUG=1 ;;
    esac
done

load_screen_cache

_SETUP_OUT=$(CACHE_FILE="$CACHE_FILE" STATE_FILE="$STATE_FILE" python3 "$SCRIPT_DIR/lib/setup-dev-state.py")
ROTATION=$(echo "$_SETUP_OUT" | awk 'NR==1')
VSCODE_SCREEN=$(echo "$_SETUP_OUT" | awk 'NR==2')
BROWSER_SCREEN=$(echo "$_SETUP_OUT" | awk 'NR==3')
TERMINAL_SCREEN=$(echo "$_SETUP_OUT" | awk 'NR==4')
DISPLAY_LABELS=$(echo "$_SETUP_OUT" | awk 'NR==5')

read -r VX VY VW VH <<< "$VSCODE_SCREEN"
read -r BX BY BW BH <<< "$BROWSER_SCREEN"
read -r TX TY TW TH <<< "$TERMINAL_SCREEN"
read -r VSCODE_DISPLAY BROWSER_DISPLAY TERMINAL_DISPLAY <<< "$DISPLAY_LABELS"

export SETUP_ROTATION="$ROTATION"
export SETUP_VSCODE_X="$VX" SETUP_VSCODE_Y="$VY" SETUP_VSCODE_W="$VW" SETUP_VSCODE_H="$VH"
export SETUP_BROWSER_X="$BX" SETUP_BROWSER_Y="$BY" SETUP_BROWSER_W="$BW" SETUP_BROWSER_H="$BH"
export SETUP_TERMINAL_X="$TX" SETUP_TERMINAL_Y="$TY" SETUP_TERMINAL_W="$TW" SETUP_TERMINAL_H="$TH"
export SETUP_VSCODE_DISPLAY="$VSCODE_DISPLAY"
export SETUP_BROWSER_DISPLAY="$BROWSER_DISPLAY"
export SETUP_TERMINAL_DISPLAY="$TERMINAL_DISPLAY"
export SETUP_DEBUG="$DEBUG"

RESULT=$(osascript "$SCRIPT_DIR/lib/setup-dev.applescript")
echo "$RESULT"