---
allowed-tools: Bash, Read, Write
---

# Install

Install CCPM into any project with automatic configuration.

## Usage
```
/pm:install [target-project-path]    # Install ccpm into project
/pm:install                          # Install into current directory
```

## Examples
```
/pm:install /path/to/my-project
/pm:install ../my-react-app
/pm:install
```

## Instructions

Execute the installation script:

```bash
.claude/scripts/pm/install.sh $ARGUMENTS
```

## Installation Process

1. **Detect Project Type**: Automatically identifies Node.js, Python, Java, Rust, Go, etc.
2. **Copy CCPM Structure**: Installs all commands, scripts, and agents
3. **Create Configuration**: Generates project-specific CLAUDE.md
4. **Setup Git Hooks**: Installs quality gates (optional)
5. **Create Starter Vision**: Optionally creates initial product vision

## Project Types Supported

**Node.js Projects:**
- Detects npm, yarn, or pnpm
- Configures lint, test, build, dev commands
- Sets up package.json script integration

**Python Projects:**
- Detects pyproject.toml, requirements.txt, setup.py
- Configures ruff, pytest, build tools
- Sets up virtual environment compatibility

**Java/Gradle Projects:**
- Detects build.gradle, build.gradle.kts
- Configures gradle tasks for lint, test, build
- Sets up checkstyle, detekt integration

**Maven Projects:**
- Detects pom.xml
- Configures maven goals
- Sets up checkstyle integration

**Rust Projects:**
- Detects Cargo.toml
- Configures cargo clippy, test, build
- Sets up rustfmt integration

**Go Projects:**
- Detects go.mod
- Configures golangci-lint, testing
- Sets up go fmt integration

## Generated Files

**`.claude/` Directory Structure:**
```
.claude/
├── scripts/pm/          # All PM scripts
├── commands/pm/         # Command definitions  
├── agents/             # Quality guardian agents
├── visions/            # Vision storage
├── epics/              # Epic storage
├── prds/               # PRD storage
└── plans/              # Fix plans
```

**`CLAUDE.md` Configuration:**
- Project type and commands
- Quick start guide
- Quality assurance setup
- Command reference

**Git Integration:**
- Pre-commit quality gates
- Automatic validation
- Bypass options for emergencies

## Post-Installation

After installation:
```bash
/pm:help                    # View all commands
/pm:vision-new my-product   # Create product vision  
/pm:prd-new feature-name    # Start first feature
/pm:fix-all                 # Run quality check
```

## Integration Benefits

- **Zero Configuration**: Works out-of-the-box for most projects
- **Project-Aware**: Detects tools and configures accordingly
- **Quality Gates**: Automatic validation in development workflow
- **Team Ready**: All commands available immediately for team members
- **Strategic Planning**: Vision-driven development from day one

Perfect for adding enterprise-grade project management to any codebase.