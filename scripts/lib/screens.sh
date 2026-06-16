#!/bin/bash
# Shared screen geometry cache for productivity scripts.

: "${CACHE_DIR:=$HOME/.kodez}"
: "${CACHE_FILE:=$CACHE_DIR/screen-cache.json}"
: "${REFRESH:=0}"

mkdir -p "$CACHE_DIR"

screen_probe() {
    osascript -l JavaScript <<'JS'
ObjC.import('AppKit');
var screens = $.NSScreen.screens;
var mainH = screens.objectAtIndex(0).frame.size.height;
var out = { version: 1, screens: [] };
for (var i = 0; i < screens.count; i++) {
    var f = screens.objectAtIndex(i).frame;
    out.screens.push({
        x: Math.round(f.origin.x),
        y: Math.round(mainH - f.origin.y - f.size.height),
        width: Math.round(f.size.width),
        height: Math.round(f.size.height)
    });
}
JSON.stringify(out);
JS
}

screen_count() {
    osascript -l JavaScript -e 'ObjC.import("AppKit"); JSON.stringify($.NSScreen.screens.count);'
}

cache_valid() {
    [[ -f "$CACHE_FILE" ]] || return 1
    local cached_count live_count
    cached_count=$(python3 -c "import json; print(len(json.load(open('$CACHE_FILE'))['screens']))" 2>/dev/null) || return 1
    live_count=$(screen_count 2>/dev/null) || return 1
    [[ "$cached_count" == "$live_count" ]]
}

load_screen_cache() {
    if [[ "$REFRESH" -eq 1 ]] || ! cache_valid; then
        screen_probe > "$CACHE_FILE"
    fi
}

get_screen_dims() {
    local display_num="${1:-1}"
    python3 -c "
import json
data = json.load(open('$CACHE_FILE'))
idx = max(0, min(int('$display_num') - 1, len(data['screens']) - 1))
s = data['screens'][idx]
print(s['x'], s['y'], s['width'], s['height'])
"
}

get_all_screens_json() {
    python3 -c "import json; print(json.dumps(json.load(open('$CACHE_FILE'))['screens']))"
}