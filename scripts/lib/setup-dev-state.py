#!/usr/bin/env python3
import json
import os
import sys

cache_file = os.environ["CACHE_FILE"]
state_file = os.environ["STATE_FILE"]

with open(cache_file) as f:
    screens = json.load(f)["screens"]

rotation = 0
if os.path.exists(state_file):
    try:
        with open(state_file) as f:
            rotation = int(json.load(f).get("rotation", 0))
    except (json.JSONDecodeError, ValueError):
        rotation = 0

n = len(screens)
if n == 0:
    sys.exit("No displays found in screen cache")

base = [
    {"vscode": 0, "browser": 1 % n, "terminal": 2 % n},
    {"vscode": 1 % n, "browser": 2 % n, "terminal": 0},
    {"vscode": 2 % n, "browser": 0, "terminal": 1 % n},
]
assign = base[rotation % 3]

next_rotation = (rotation + 1) % 3
with open(state_file, "w") as f:
    json.dump({"profile": "dev", "rotation": next_rotation}, f, indent=2)

def screen_line(key):
    s = screens[assign[key]]
    return f"{s['x']} {s['y']} {s['width']} {s['height']}"

print(rotation)
print(screen_line("vscode"))
print(screen_line("browser"))
print(screen_line("terminal"))
print(assign["vscode"] + 1, assign["browser"] + 1, assign["terminal"] + 1)