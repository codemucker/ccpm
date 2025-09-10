#!/bin/bash

# PM Vision Edit System
# Edit vision files with validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
VISIONS_DIR="$PROJECT_ROOT/.claude/visions"

show_help() {
    echo "📝 PM Vision Edit"
    echo ""
    echo "Usage:"
    echo "  /pm:vision-edit <vision-name>     # Edit vision file"
    echo ""
    echo "Examples:"
    echo "  /pm:vision-edit marketplace-platform"
    echo "  /pm:vision-edit user-experience"
}

if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

VISION_NAME="$1"
VISION_FILE="$VISIONS_DIR/$VISION_NAME.md"

# Check if vision exists
if [[ ! -f "$VISION_FILE" ]]; then
    echo "❌ Vision not found: $VISION_NAME"
    echo "   Expected: $VISION_FILE"
    echo ""
    echo "📋 Available visions:"
    if [[ -d "$VISIONS_DIR" ]]; then
        for vision_file in "$VISIONS_DIR"/*.md; do
            if [[ -f "$vision_file" ]]; then
                vision=$(basename "$vision_file" .md)
                title=$(grep "^# " "$vision_file" | head -1 | sed 's/^# //' 2>/dev/null || echo "$vision")
                echo "   • $vision: $title"
            fi
        done
    else
        echo "   No visions found."
    fi
    exit 1
fi

echo "📝 Opening vision for editing: $VISION_NAME"
echo "   File: $VISION_FILE"

# Get vision title for context
VISION_TITLE=$(grep "^# " "$VISION_FILE" | head -1 | sed 's/^# //' 2>/dev/null || echo "$VISION_NAME")
echo "   Title: $VISION_TITLE"

# Open in editor
# Try different editors in order of preference
if [[ -n "$EDITOR" ]]; then
    $EDITOR "$VISION_FILE"
elif command -v code >/dev/null 2>&1; then
    code "$VISION_FILE"
elif command -v nano >/dev/null 2>&1; then
    nano "$VISION_FILE"
elif command -v vi >/dev/null 2>&1; then
    vi "$VISION_FILE"
else
    echo "⚠️  No suitable editor found. Please edit manually:"
    echo "   File: $VISION_FILE"
    exit 1
fi

echo ""
echo "✅ Vision editing session completed"

# Offer to validate the updated vision
echo ""
read -p "🔍 Run vision audit to check epic links? (y/n): " RUN_AUDIT

if [[ "$RUN_AUDIT" =~ ^[Yy] ]]; then
    echo ""
    "$SCRIPT_DIR/vision-audit.sh"
fi

echo ""
echo "🔧 Next steps:"
echo "   /pm:vision-list --tree          # View vision hierarchy"
echo "   /pm:vision-audit                # Audit all epic links"  
echo "   /pm:vision-match --epic <name>  # Match epics to this vision"

exit 0