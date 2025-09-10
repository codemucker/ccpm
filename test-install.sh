#!/bin/bash

# Test CCPM Installation
# Verifies that install.sh works correctly

set -e

TEMP_PROJECT="/tmp/ccpm-test-project-$$"
CCPM_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 Testing CCPM Installation"
echo "============================="
echo ""

# Create test project
echo "📁 Creating test project..."
mkdir -p "$TEMP_PROJECT"
cd "$TEMP_PROJECT"

# Create a simple Node.js project
cat > "package.json" << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "scripts": {
    "lint": "eslint .",
    "test": "jest",
    "build": "webpack",
    "dev": "webpack-dev-server"
  }
}
EOF

echo "✅ Test project created: $TEMP_PROJECT"

# Run installer
echo ""
echo "🚀 Running CCPM installer..."
if "$CCPM_PATH/.claude/scripts/pm/install.sh" "$TEMP_PROJECT"; then
    echo "✅ Installation completed"
else
    echo "❌ Installation failed"
    exit 1
fi

# Verify installation
echo ""
echo "🔍 Verifying installation..."

# Check directory structure
CHECKS=(
    ".claude/scripts/pm/help.sh"
    ".claude/commands/pm/vision-new.md"
    ".claude/agents/quality-guardian.md"
    "CLAUDE.md"
)

FAILED=0
for check in "${CHECKS[@]}"; do
    if [[ -f "$TEMP_PROJECT/$check" ]]; then
        echo "✅ $check"
    else
        echo "❌ $check"
        FAILED=1
    fi
done

# Test a command
echo ""
echo "🎯 Testing PM commands..."
cd "$TEMP_PROJECT"

if [[ -x ".claude/scripts/pm/help.sh" ]] && .claude/scripts/pm/help.sh | grep -q "Vision Commands"; then
    echo "✅ PM commands working"
else
    echo "❌ PM commands not working"
    FAILED=1
fi

# Check configuration
if grep -q "nodejs" "CLAUDE.md" && grep -q "npm run" "CLAUDE.md"; then
    echo "✅ Project detection working (Node.js detected)"
else
    echo "❌ Project detection failed"
    FAILED=1
fi

# Cleanup
echo ""
echo "🧹 Cleaning up..."
rm -rf "$TEMP_PROJECT"

# Results
echo ""
if [[ $FAILED -eq 0 ]]; then
    echo "🎉 Installation test PASSED"
    echo ""
    echo "✅ CCPM installer is working correctly"
    echo "✅ All files installed properly"  
    echo "✅ Commands are functional"
    echo "✅ Project detection working"
    exit 0
else
    echo "❌ Installation test FAILED"
    echo ""
    echo "Some checks failed. Please review the installer."
    exit 1
fi