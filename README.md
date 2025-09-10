# CCPM - Claude Code Project Management

Vision-driven project management with automated quality assurance.

## 🚀 Quick Start

### One-Line Install (Always Latest)

```bash
# Install into current directory
curl -sSL https://raw.githubusercontent.com/codemucker/ccpm/main/quick-install.sh | bash

# Install into specific project
curl -sSL https://raw.githubusercontent.com/codemucker/ccpm/main/quick-install.sh | bash -s /path/to/project
```

### Self-Install (No Confirmation)

```bash
# Clone repo, then self-install from anywhere
git clone https://github.com/codemucker/ccpm.git
cd /your/project/directory
/path/to/ccpm/.claude/scripts/pm/install.sh .
```

### Manual Install

```bash  
# Clone and install into specific project
git clone https://github.com/codemucker/ccpm.git
cd ccpm
./.claude/scripts/pm/install.sh /path/to/your/project
```

### What You Get Instantly

```bash
# Vision-driven workflow
/pm:vision-new my-product           # Create product vision
/pm:vision-new-sub user-experience  # Create sub-vision
/pm:prd-new feature-name            # Create feature requirement
/pm:prd-parse feature-name          # Convert to epic
/pm:vision-match --epic feature-name # Link to vision

# Quality assurance
/pm:fix-all                         # Analyze and fix all issues
/pm:code-review                     # SOLID principles review
/pm:anti-cheat                      # Detect fake implementations
/pm:validate                        # Comprehensive validation

# Strategic oversight
/pm:vision-tree                     # View strategic hierarchy
/pm:vision-orphans                  # Find unaligned work
/pm:status                          # Project dashboard
/pm:help                            # All commands
```

## 🎯 Features

- **Vision-Driven Development**: Every line of code traces to business strategy
- **Automated Quality Assurance**: SOLID principles, cheat detection, zero-tolerance validation
- **Smart Project Detection**: Auto-configures for Node.js, Python, Java, Rust, Go
- **GitHub Integration**: Visions and epics sync as GitHub issues
- **Linear Fix Planning**: Generate and execute fix plans without commentary
- **Team Ready**: Zero configuration for team members

## 📁 Project Structure After Install

```
your-project/
├── .claude/
│   ├── scripts/pm/     # 30+ PM commands
│   ├── commands/pm/    # Command definitions
│   ├── agents/         # Quality guardian
│   ├── visions/        # Strategic storage
│   ├── epics/          # Epic management
│   ├── prds/           # Requirements
│   └── plans/          # Fix plans
├── CLAUDE.md           # Project config
└── .git/hooks/         # Quality gates
```

## 🔧 Examples

### Basic Workflow
```bash
# 1. Create strategic context
/pm:vision-new marketplace-platform
/pm:vision-new-sub user-experience

# 2. Add feature  
/pm:prd-new user-authentication
/pm:prd-parse user-authentication
/pm:vision-match --epic user-authentication

# 3. Quality check
/pm:fix-all
```

### Quality Automation
```bash
# Generate fix plan from all issues
/pm:plan-fixes src/

# Execute plan.md silently with LLM
/pm:plan-execute
```

### Strategic Oversight
```bash
# View hierarchy
/pm:vision-tree

# Find unaligned work  
/pm:vision-orphans

# Project dashboard
/pm:status
```

## 🛡️ Quality Standards

- **Code Review**: SOLID, DRY, KISS, ROCO, POLA, YAGNI
- **Cheat Detection**: Hardcoded responses, fake logic, shortcuts
- **Zero Tolerance**: All lint, test, build, runtime must pass
- **Linear Fixes**: Automated execution without commentary

## 📚 Full Documentation

- `INTEGRATION.md` - Complete installation guide
- `/pm:help` - All available commands  
- Type any `/pm:` command for usage help
- Auto-generated `CLAUDE.md` in your project

---

**Ready to transform your development workflow?**

```bash
git clone https://github.com/codemucker/ccpm.git
cd ccpm  
./.claude/scripts/pm/install.sh /path/to/your/project
```