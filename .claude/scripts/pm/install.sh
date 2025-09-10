#!/bin/bash

# CCPM Auto-Installer
# Automatically integrates ccpm into any project

set -e

# Find CCPM repo path (script is at ccpm/.claude/scripts/pm/install.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CCPM_REPO_PATH="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Find target project path with git repo detection
find_git_repo() {
    local dir="$1"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Determine target directory
if [[ "$1" == "." ]]; then
    # Special case: installing into current project
    if GIT_ROOT=$(find_git_repo "$(pwd)"); then
        TARGET_PROJECT_PATH="$GIT_ROOT"
        SELF_INSTALL=true
        echo "🎯 Self-install mode: Found git repo at $GIT_ROOT"
    else
        echo "❌ No git repository found in current directory or parent directories"
        echo "   Initialize git first: git init"
        exit 1
    fi
elif [[ -n "$1" ]]; then
    TARGET_PROJECT_PATH="$1"
    SELF_INSTALL=false
else
    # Default to current directory
    TARGET_PROJECT_PATH="$(pwd)"
    SELF_INSTALL=false
fi

show_help() {
    echo "🚀 CCPM Auto-Installer"
    echo ""
    echo "Usage:"
    echo "  ./install.sh .                        # Self-install into current git repo"
    echo "  ./install.sh [target-project-path]    # Install ccpm into specific project"
    echo "  ./install.sh                          # Install into current directory"
    echo ""
    echo "Examples:"
    echo "  # Self-install (finds git repo automatically, no confirmation):"
    echo "  ./.claude/scripts/pm/install.sh ."
    echo ""
    echo "  # Install into specific project:"
    echo "  ./.claude/scripts/pm/install.sh /path/to/my-project"
    echo ""  
    echo "  # Install into current directory:"
    echo "  ./.claude/scripts/pm/install.sh"
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

echo "🚀 CCPM Auto-Installer"
echo "======================"
echo ""
echo "Source: $CCPM_REPO_PATH"
echo "Target: $TARGET_PROJECT_PATH"

# Show git repo status
if [[ -d "$TARGET_PROJECT_PATH/.git" ]]; then
    echo "Git Repo: ✅ Found"
    if [[ "$SELF_INSTALL" == "true" ]]; then
        echo "Mode: Self-install (no confirmation needed)"
    fi
else
    echo "Git Repo: ⚠️  Not found"
fi

echo ""

# Validate target directory
if [[ ! -d "$TARGET_PROJECT_PATH" ]]; then
    echo "❌ Target directory does not exist: $TARGET_PROJECT_PATH"
    exit 1
fi

cd "$TARGET_PROJECT_PATH"

# Check if already installed (simple check)
ALREADY_INSTALLED=false

echo "🔍 Checking for existing CCPM installation..."

# Simple check - if help.sh and vision-new.sh both exist, consider it installed
if [[ -f ".claude/scripts/pm/help.sh" ]] && [[ -f ".claude/scripts/pm/vision-new.sh" ]] && [[ -f ".claude/commands/pm/vision-new.md" ]]; then
    ALREADY_INSTALLED=true
    echo "✅ CCPM appears to already be installed."
    echo ""
    
    if [[ "$SELF_INSTALL" == "true" ]]; then
        echo "🔄 Self-install mode: Updating existing installation..."
    else
        read -p "Reinstall/update? (y/N): " REINSTALL
        if [[ ! "$REINSTALL" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
        echo ""
        echo "🔄 Updating existing installation..."
    fi
elif [[ -f ".claude/scripts/pm/help.sh" ]] || [[ -d ".claude/scripts/pm" ]]; then
    echo "⚠️  Partial CCPM installation detected."
    echo "   This suggests a previous installation failed or was incomplete."
    echo "   Proceeding with full installation to fix missing files..."
    echo ""
fi

echo "🔧 Proceeding with installation..."

# Confirmation for new installs (unless self-install)
if [[ "$ALREADY_INSTALLED" == "false" ]] && [[ "$SELF_INSTALL" != "true" ]]; then
    PROJECT_NAME=$(basename "$TARGET_PROJECT_PATH")
    echo "📋 Ready to install CCPM into: $PROJECT_NAME"
    echo ""
    read -p "Continue with installation? (Y/n): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    echo ""
fi

# Step 1: Copy ccpm structure
echo "📁 Copying CCPM structure..."

# Create directory structure
mkdir -p .claude/{scripts/pm,commands/pm,agents,visions,epics,prds,plans/completed}

# Copy all PM scripts
if cp -r "$CCPM_REPO_PATH/.claude/scripts/pm"/* ".claude/scripts/pm/" 2>/dev/null; then
    # Ensure scripts have execute permissions
    chmod +x .claude/scripts/pm/*.sh 2>/dev/null || true
    echo "  ✅ Scripts copied and made executable"
else
    echo "  ❌ Failed to copy scripts from: $CCPM_REPO_PATH/.claude/scripts/pm/"
    exit 1
fi

# Copy all PM commands  
if cp -r "$CCPM_REPO_PATH/.claude/commands/pm"/* ".claude/commands/pm/" 2>/dev/null; then
    echo "  ✅ Commands copied"
else
    echo "  ❌ Failed to copy commands from: $CCPM_REPO_PATH/.claude/commands/pm/"
    exit 1
fi

# Copy agents
if cp -r "$CCPM_REPO_PATH/.claude/agents"/* ".claude/agents/" 2>/dev/null; then
    echo "  ✅ Agents copied"
else
    echo "  ❌ Failed to copy agents from: $CCPM_REPO_PATH/.claude/agents/"
    exit 1
fi

echo "✅ CCPM structure copied"

# Step 2: Detect project type and create initial configuration
echo ""
echo "🔍 Detecting project type..."

PROJECT_TYPE="unknown"
PACKAGE_MANAGER=""
LINT_COMMAND=""
TEST_COMMAND=""  
BUILD_COMMAND=""
DEV_COMMAND=""

# Node.js detection
if [[ -f "package.json" ]]; then
    PROJECT_TYPE="nodejs"
    if [[ -f "yarn.lock" ]]; then
        PACKAGE_MANAGER="yarn"
    elif [[ -f "pnpm-lock.yaml" ]]; then
        PACKAGE_MANAGER="pnpm"
    else
        PACKAGE_MANAGER="npm"
    fi
    
    # Try to detect scripts from package.json
    LINT_COMMAND="$PACKAGE_MANAGER run lint"
    TEST_COMMAND="$PACKAGE_MANAGER test"  
    BUILD_COMMAND="$PACKAGE_MANAGER run build"
    DEV_COMMAND="$PACKAGE_MANAGER run dev"
    
    echo "✅ Detected Node.js project ($PACKAGE_MANAGER)"

# Python detection
elif [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]]; then
    PROJECT_TYPE="python"
    LINT_COMMAND="ruff check ."
    TEST_COMMAND="pytest"
    BUILD_COMMAND="python -m build"
    
    echo "✅ Detected Python project"

# Java/Gradle detection
elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    PROJECT_TYPE="gradle"
    LINT_COMMAND="./gradlew check"
    TEST_COMMAND="./gradlew test"
    BUILD_COMMAND="./gradlew build"
    
    echo "✅ Detected Gradle project"

# Maven detection  
elif [[ -f "pom.xml" ]]; then
    PROJECT_TYPE="maven"
    LINT_COMMAND="mvn checkstyle:check"
    TEST_COMMAND="mvn test"
    BUILD_COMMAND="mvn compile"
    
    echo "✅ Detected Maven project"

# Rust detection
elif [[ -f "Cargo.toml" ]]; then
    PROJECT_TYPE="rust" 
    LINT_COMMAND="cargo clippy"
    TEST_COMMAND="cargo test"
    BUILD_COMMAND="cargo build"
    
    echo "✅ Detected Rust project"

# Go detection
elif [[ -f "go.mod" ]]; then
    PROJECT_TYPE="go"
    LINT_COMMAND="golangci-lint run"
    TEST_COMMAND="go test ./..."
    BUILD_COMMAND="go build"
    
    echo "✅ Detected Go project"
else
    echo "⚠️  Unknown project type - using generic configuration"
fi

# Step 3: Create project-specific CLAUDE.md
echo ""
echo "📝 Creating project configuration..."

cat > "CLAUDE.md" << EOF
# Project PM Configuration

This project uses CCPM (Claude Code Project Management) for vision-driven development.

## Project Details
- **Type**: $PROJECT_TYPE
- **Package Manager**: ${PACKAGE_MANAGER:-"N/A"}
- **Installed**: $(date '+%Y-%m-%d %H:%M:%S')

## Commands Available
- \`/pm:help\` - Show all available PM commands
- \`/pm:vision-new <name>\` - Create product vision
- \`/pm:vision-new-sub <name>\` - Create sub-vision
- \`/pm:prd-new <name>\` - Create product requirement
- \`/pm:fix-all\` - Complete quality fix workflow

## Project Commands
EOF

if [[ -n "$LINT_COMMAND" ]]; then
    echo "- **Lint**: \`$LINT_COMMAND\`" >> "CLAUDE.md"
fi
if [[ -n "$TEST_COMMAND" ]]; then
    echo "- **Test**: \`$TEST_COMMAND\`" >> "CLAUDE.md"
fi  
if [[ -n "$BUILD_COMMAND" ]]; then
    echo "- **Build**: \`$BUILD_COMMAND\`" >> "CLAUDE.md"
fi
if [[ -n "$DEV_COMMAND" ]]; then
    echo "- **Dev**: \`$DEV_COMMAND\`" >> "CLAUDE.md"
fi

cat >> "CLAUDE.md" << EOF

## Quick Start

1. **Create Vision**: \`/pm:vision-new my-product\`
2. **Create Sub-Vision**: \`/pm:vision-new-sub user-experience\`  
3. **Create PRD**: \`/pm:prd-new feature-name\`
4. **Convert to Epic**: \`/pm:prd-parse feature-name\`
5. **Link to Vision**: \`/pm:vision-match --epic feature-name\`

## Quality Assurance

- \`/pm:fix-all\` - Analyze, plan, and fix all issues
- \`/pm:code-review\` - SOLID principles review
- \`/pm:anti-cheat\` - Detect fake implementations
- \`/pm:validate\` - Comprehensive validation

## Documentation

- [Complete PM Guide](https://github.com/codemucker/ccpm)
- Type \`/pm:help\` for all commands
- Use \`/pm:vision-tree\` to view strategic hierarchy
EOF

echo "✅ CLAUDE.md configuration created"

# Step 4: Initialize Git hooks (if git repo)
if [[ -d ".git" ]]; then
    echo ""
    echo "🔗 Setting up Git integration..."
    
    mkdir -p .git/hooks
    
    # Create pre-commit hook for quality checks
    cat > ".git/hooks/pre-commit" << 'EOF'
#!/bin/bash
# CCPM Quality Gate - Auto-generated

echo "🛡️ CCPM Quality Gate"

# Run quality checks
if .claude/scripts/pm/validate.sh --quiet 2>/dev/null; then
    echo "✅ Quality checks passed"
    exit 0
else
    echo "❌ Quality checks failed"
    echo ""
    echo "Fix issues with:"
    echo "   /pm:fix-all"
    echo ""
    echo "Or bypass with:"
    echo "   git commit --no-verify"
    exit 1
fi
EOF
    
    chmod +x ".git/hooks/pre-commit"
    echo "✅ Git quality gate installed"
fi

# Step 5: Create starter vision (optional, non-interactive for automation)
if [[ -t 0 ]]; then  # Only prompt if running interactively
    echo ""
    read -p "🎯 Create starter product vision? (Y/n): " CREATE_VISION
else
    CREATE_VISION="n"  # Default to no for automated installs
fi

if [[ ! "$CREATE_VISION" =~ ^[Nn]$ ]]; then
    PROJECT_NAME=$(basename "$TARGET_PROJECT_PATH")
    VISION_NAME=$(echo "$PROJECT_NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')
    
    echo ""
    echo "Creating starter vision: $VISION_NAME"
    
    echo "💡 Starter vision can be created after installation with:"
    echo "   /pm:vision-new $VISION_NAME"
fi

# Step 6: Final setup
echo ""
echo "🎉 CCPM Installation Complete!"
echo "=============================="
echo ""
echo "📁 Project: $TARGET_PROJECT_PATH"
echo "🎯 Type: $PROJECT_TYPE"
echo "📋 Configuration: CLAUDE.md"
echo ""
echo "🚀 Next Steps:"
echo "   1. /pm:help                    # View all commands"
echo "   2. /pm:vision-tree             # View strategic hierarchy" 
echo "   3. /pm:prd-new <feature>       # Create your first feature"
echo "   4. /pm:fix-all                 # Quality check"
echo ""
echo "📚 Documentation:"
echo "   - Type /pm:help for command reference"
echo "   - See CLAUDE.md for project-specific setup"
echo "   - Visit https://github.com/codemucker/ccpm for full guide"

# Check if Claude Code is available
if [[ -n "$CLAUDE_CODE_SESSION" ]]; then
    echo ""
    echo "🤖 Claude Code detected - CCPM commands ready to use!"
else
    echo ""
    echo "💡 Run this from Claude Code for full PM command access"
fi

exit 0