#!/bin/bash

# PM Sub-Vision Creation System
# Creates new sub-vision with GitHub integration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    echo "🎭 PM Sub-Vision Creation"
    echo ""
    echo "Usage:"
    echo "  /pm:vision-new-sub <sub-vision-name>"
    echo ""
    echo "Examples:"
    echo "  /pm:vision-new-sub user-experience"
    echo "  /pm:vision-new-sub data-insights"
}

if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

SUB_VISION_NAME="$1"

echo "🎭 Creating sub-vision: $SUB_VISION_NAME"

# Call the main vision-new script with --sub flag
"$SCRIPT_DIR/vision-new.sh" "$SUB_VISION_NAME" --sub

exit 0