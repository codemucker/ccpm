#!/bin/bash

# CCPM Quick Installer - One-line installation for any project
# Usage: curl -sSL https://raw.githubusercontent.com/codemucker/ccpm/main/install.sh | bash

set -e

CCPM_VERSION="main"
CCPM_REPO="https://github.com/codemucker/ccpm"
TARGET_DIR="${1:-$(pwd)}"
TEMP_DIR="/tmp/ccpm-install-$$"

echo "🚀 CCPM Quick Installer"
echo "======================="
echo ""
echo "Installing into: $TARGET_DIR"
echo ""

# Create temporary directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download CCPM
echo "📥 Downloading CCPM..."
if command -v git >/dev/null 2>&1; then
    git clone --depth 1 "$CCPM_REPO.git" ccpm
else
    echo "❌ Git not found. Please install git or use manual installation."
    exit 1
fi

# Run installer
echo ""
echo "🔧 Running installer..."
cd ccpm
./.claude/scripts/pm/install.sh "$TARGET_DIR"

# Cleanup
echo ""
echo "🧹 Cleaning up..."
cd /
rm -rf "$TEMP_DIR"

echo ""
echo "✅ CCPM installation complete!"
echo ""
echo "From your project directory, try:"
echo "   /pm:help        # View all commands"
echo "   /pm:vision-new my-product  # Create product vision"

exit 0