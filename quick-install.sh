#!/bin/bash
# CCPM Quick Install - Always fetches latest version
# Usage: curl -sSL https://raw.githubusercontent.com/codemucker/ccpm/main/quick-install.sh | bash

set -e

CCPM_REPO="https://github.com/codemucker/ccpm"
CCPM_BRANCH="main"
TARGET_DIR="${1:-$(pwd)}"
TEMP_DIR="/tmp/ccpm-install-$$"

echo "🚀 CCPM Quick Installer (Always Latest)"
echo "========================================"
echo ""
echo "Target: $TARGET_DIR"
echo "Temp: $TEMP_DIR"
echo ""

# Create temp directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download latest CCPM
echo "📥 Downloading latest CCPM..."
if command -v git >/dev/null 2>&1; then
    git clone --depth 1 --branch "$CCPM_BRANCH" "$CCPM_REPO.git" ccpm
    echo "✅ Downloaded from $CCPM_REPO ($CCPM_BRANCH)"
else
    echo "❌ Git required. Install git first:"
    echo "   # Ubuntu/Debian: sudo apt install git"
    echo "   # macOS: brew install git"  
    echo "   # Windows: winget install Git.Git"
    exit 1
fi

# Run installation
echo ""
echo "🔧 Installing CCPM..."
cd ccpm
if ./.claude/scripts/pm/install.sh "$TARGET_DIR"; then
    echo ""
    echo "✅ Installation successful!"
else
    echo ""
    echo "❌ Installation failed"
    exit 1
fi

# Cleanup
echo ""
echo "🧹 Cleaning up..."
cd /
rm -rf "$TEMP_DIR"

echo ""
echo "🎉 CCPM Ready!"
echo ""
echo "From your project directory:"
echo "   /pm:help                    # View all commands"
echo "   /pm:vision-new my-product   # Create product vision"  
echo "   /pm:fix-all                 # Quality check"

exit 0