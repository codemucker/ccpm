#!/bin/bash

# PM Vision Tree View
# Quick command to show vision hierarchy

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🌳 Vision Hierarchy"

# Call vision-list with --tree flag
"$SCRIPT_DIR/vision-list.sh" --tree

exit 0