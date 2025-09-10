# PM Vision GitHub Integration

Creates GitHub issues for existing visions that don't have them yet.

## Usage

```bash
/pm:vision-github                    # Create issues for all visions missing them
/pm:vision-github <vision-name>     # Create issue for specific vision  
/pm:vision-github --list             # List visions and their GitHub status
```

## Examples

```bash
# Auto-create missing issues for all visions
/pm:vision-github

# Create issue for specific vision
/pm:vision-github marketplace

# Show which visions have/need GitHub issues
/pm:vision-github --list
```

## What It Does

1. **Scans existing visions** for missing GitHub issues
2. **Creates labeled issues** with vision content and tracking structure
3. **Updates vision files** with GitHub issue numbers
4. **Maintains traceability** between local visions and GitHub issues

## Requirements

- GitHub CLI (`gh`) must be installed and authenticated
- Vision files must exist in `.claude/visions/`
- Must be run from within a git repository

## Output

- Lists which visions already have issues (skipped)
- Creates new issues for visions with `_TBD_` placeholders
- Updates vision files with `**GitHub Issue:** #123` links
- Provides summary of created vs skipped issues

Perfect for setting up GitHub tracking after creating visions locally first.