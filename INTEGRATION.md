# CCPM Integration Guide

Add vision-driven project management to any codebase in 60 seconds.

## 🚀 Quick Installation

### Method 1: Git Clone + Install (Recommended)
```bash
# Clone ccpm repo
git clone https://github.com/codemucker/ccpm.git

# Install into your project from ccpm directory  
cd ccpm
./.claude/scripts/pm/install.sh /path/to/your/project

# Or install into current directory
cd /path/to/your/project
/path/to/ccpm/.claude/scripts/pm/install.sh
```

### Method 2: One-Line Download + Install
```bash
# Download and install automatically
curl -sSL https://raw.githubusercontent.com/codemucker/ccpm/main/install.sh | bash
```

### Method 3: From Existing Claude Code Session
```bash
# If you already have ccpm loaded in Claude Code
/pm:install /path/to/your/project
/pm:install  # Install in current directory  
```

## 🎯 What Gets Installed

### Directory Structure
```
your-project/
├── .claude/
│   ├── scripts/pm/     # All PM commands (30+ scripts)
│   ├── commands/pm/    # Command definitions  
│   ├── agents/         # Quality guardian agents
│   ├── visions/        # Strategic vision storage
│   ├── epics/          # Epic management
│   ├── prds/           # Product requirements
│   └── plans/          # Fix plan archive
├── CLAUDE.md           # Project-specific configuration
└── .git/hooks/         # Quality gate integration (if git repo)
```

### Auto-Configuration
The installer automatically detects and configures:

**Node.js Projects** (package.json)
- npm/yarn/pnpm detection
- Script integration (lint, test, build, dev)
- ESLint, Prettier, TypeScript support

**Python Projects** (pyproject.toml, requirements.txt)  
- Poetry, pip, conda support
- ruff, pytest, mypy integration
- Virtual environment compatibility

**Java Projects** (build.gradle, pom.xml)
- Gradle/Maven detection
- Checkstyle, SpotBugs integration
- Kotlin multiplatform support

**Rust Projects** (Cargo.toml)
- Cargo clippy, rustfmt integration
- Test and benchmark configuration

**Go Projects** (go.mod)
- golangci-lint integration
- Module and workspace support

## 🎉 Instant Usage

After installation, immediately available:

### Vision-Driven Workflow
```bash
/pm:vision-new my-product           # Create product vision
/pm:vision-new-sub user-experience  # Create strategic theme
/pm:prd-new user-onboarding         # Create feature requirement  
/pm:prd-parse user-onboarding       # Convert to technical epic
/pm:vision-match --epic user-onboarding # Link to vision
```

### Quality Assurance
```bash
/pm:fix-all                         # Complete fix workflow
/pm:code-review                     # SOLID principles analysis  
/pm:anti-cheat                      # Detect fake implementations
/pm:validate                        # Comprehensive validation
```

### Strategic Oversight  
```bash
/pm:vision-tree                     # View hierarchy
/pm:vision-orphans                  # Find unaligned work
/pm:status                          # Project dashboard
```

## 🛡️ Built-in Quality Gates

### Git Integration
- **Pre-commit hooks**: Automatic quality validation
- **Quality gates**: Prevent bad code from entering repo
- **Bypass options**: Emergency commit capabilities

### Zero-Tolerance Validation
- **Linting**: Must pass with zero errors
- **Testing**: All tests must pass  
- **Building**: Successful compilation required
- **Runtime**: Application must start correctly

## 🌟 Team Benefits

### For Developers
- **No Learning Curve**: Commands are discoverable (`/pm:` + tab)
- **Quality Automation**: Fix issues automatically with linear plans
- **Strategic Context**: Always know why you're building features

### For Product Managers  
- **Vision Tracking**: Every epic traces to business strategy
- **Progress Visibility**: Real-time alignment dashboard
- **Strategic Planning**: Sub-visions organize complex products

### For Engineering Managers
- **Quality Assurance**: Automated code review and cheat detection
- **Strategic Alignment**: No orphaned work, everything has business justification
- **Team Coordination**: Shared vision and epic management

## 🔧 Customization

After installation, customize via `CLAUDE.md`:

```markdown
## Project Commands
- **Lint**: `npm run lint --fix`
- **Test**: `npm test -- --coverage`  
- **Build**: `npm run build:prod`
- **Dev**: `npm run dev --port 3000`
```

## 📈 Advanced Features

### Strategic Planning
- **Vision Hierarchy**: Product visions with sub-vision themes
- **Epic Alignment**: Smart LLM matching of work to strategy
- **Traceability**: Vision → Epic → Tasks → Issues → Code

### Quality Automation
- **Linear Fix Plans**: Generated task lists with zero commentary
- **Silent Execution**: LLM fixes issues without explanation noise
- **Comprehensive Validation**: Lint + test + build + runtime verification

### GitHub Integration
- **Issue Tracking**: Visions and epics sync to GitHub issues
- **Team Visibility**: Strategic context in familiar tools
- **Link Maintenance**: Automatic relationship management

## 🆘 Support

- **Help System**: `/pm:help` shows all available commands
- **Documentation**: Complete command reference built-in
- **Project Detection**: Automatic configuration for most project types
- **Error Recovery**: Clear guidance when things go wrong

## 🚀 Getting Started

1. **Install** (60 seconds): One-line curl command
2. **Create Vision** (2 minutes): `/pm:vision-new my-product`  
3. **Add Feature** (5 minutes): `/pm:prd-new feature → /pm:prd-parse feature`
4. **Quality Check** (30 seconds): `/pm:fix-all`
5. **Team Ready** (immediate): Share repo, commands work for everyone

**Total setup time: Under 10 minutes for full enterprise project management.**

---

**Ready to transform your development workflow?**

```bash
curl -sSL https://raw.githubusercontent.com/codemucker/ccpm/main/install.sh | bash
```