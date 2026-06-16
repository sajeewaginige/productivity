#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
    cat <<EOF
Usage:
  mac setup dev [--refresh] [--debug]   Lay out dev apps across 3 displays (rotates on repeat)
  mac reorg [display]         Reorganize all apps on one display (4x3 grid)
  mac reorg --refresh [n]     Rebuild screen cache, then reorganize

Examples:
  mac setup dev
  mac reorg 2
  mac reorg --refresh 1
EOF
}

case "${1:-}" in
    setup)
        shift
        case "${1:-}" in
            dev)
                shift
                exec "$SCRIPT_DIR/setup-dev.sh" "$@"
                ;;
            *)
                echo "Unknown setup profile: ${1:-}" >&2
                usage
                exit 1
                ;;
        esac
        ;;
    reorg)
        shift
        exec "$SCRIPT_DIR/reorg.sh" "$@"
        ;;
    -h|--help|help|"")
        usage
        [[ -n "${1:-}" ]] || exit 0
        exit 0
        ;;
    *)
        echo "Unknown command: $1" >&2
        usage
        exit 1
        ;;
esac