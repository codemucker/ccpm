#!/bin/bash

# PM Vision Orphans Check
# Quick command to show epics without vision links

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚨 Orphaned Epics (No Vision Links)"

# Call vision-audit with --orphans flag
"$SCRIPT_DIR/vision-audit.sh" --orphans

exit 0