# PM Intelligent Sync System

Auto-detects and fixes GitHub/local vision inconsistencies using AI. Adapts to your team's preferred workflow automatically.

## Usage

```bash
/pm:sync                    # Auto-detect and fix all inconsistencies
/pm:sync --dry-run          # Show what would be synced without making changes
/pm:sync --github-first     # Prioritize GitHub as source of truth
/pm:sync --local-first      # Prioritize local files as source of truth
```

## What It Detects and Fixes

### Workflow Detection
- **GitHub-first teams**: More issues than local files → syncs issues to local
- **Local-first teams**: More local files → creates missing GitHub issues  
- **Balanced teams**: Uses AI to intelligently resolve conflicts

### Automatic Fixes
- ✅ **Missing local files**: Creates from GitHub issues
- ✅ **Missing GitHub issues**: Creates from local vision files
- ✅ **Broken links**: Fixes vision ↔ epic ↔ issue relationships
- ✅ **Wrong issue numbers**: Updates local files with correct GitHub links
- ✅ **Missing labels**: Creates standard PM label system
- ✅ **Orphaned epics**: Uses AI to match epics to appropriate visions

### AI-Powered Intelligence
- Detects team workflow preferences automatically
- Uses vision-matching AI for orphaned epics
- Intelligently resolves content conflicts
- Maintains strategic alignment across all artifacts

## Standard Label System

Automatically creates and maintains:
- `vision` / `sub-vision` - Strategic alignment
- `epic` / `story` / `task` - Work breakdown hierarchy
- `priority::high|medium|low` - Prioritization levels

## Examples

```bash
# Daily sync - fixes everything automatically
/pm:sync

# Check what needs fixing without making changes
/pm:sync --dry-run

# Force GitHub as authoritative source
/pm:sync --github-first

# Prioritize local files over GitHub
/pm:sync --local-first
```

Perfect for keeping vision-driven development synchronized across GitHub and local development environments.