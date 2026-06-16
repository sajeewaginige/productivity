#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
    cat <<EOF
Usage:
  mac window setup dev [--refresh] [--debug]   Dev layout across 3 displays (rotates each run)
  mac w s dev [--refresh] [--debug]            Short form
  mac window sweep [display]                   Sweep all apps onto one display (4x3 grid)
  mac w sweep [display]                        Short form
  mac w sw [display]                           Shorter alias for sweep

Examples:
  mac window setup dev
  mac w s dev
  mac window sweep 2
  mac w sw --refresh 1
EOF
}

expand_token() {
    case "${1:-}" in
        w|window)   echo "window" ;;
        s|setup)    echo "setup" ;;
        sw|sweep)   echo "sweep" ;;
        *)          echo "${1:-}" ;;
    esac
}

if [[ $# -eq 0 || "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
    usage
    exit 0
fi

cmd=$(expand_token "$1")
shift

case "$cmd" in
    window)
        sub=$(expand_token "${1:-}")
        shift
        case "$sub" in
            setup)
                profile="${1:-}"
                shift
                case "$profile" in
                    dev)
                        exec "$SCRIPT_DIR/setup-dev.sh" "$@"
                        ;;
                    *)
                        echo "Unknown window setup profile: ${profile:-}" >&2
                        usage
                        exit 1
                        ;;
                esac
                ;;
            sweep)
                exec "$SCRIPT_DIR/sweep.sh" "$@"
                ;;
            *)
                echo "Unknown window command: ${sub:-}" >&2
                usage
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Unknown command: $cmd" >&2
        usage
        exit 1
        ;;
esac