---
allowed-tools: Bash, Read
---

# Vision List

List all visions with status and relationships.

## Usage
```
/pm:vision-list              # List all visions
/pm:vision-list --tree       # Show vision hierarchy  
/pm:vision-list --status     # Include progress status
```

## Instructions

Execute the vision listing script:

```bash
.claude/scripts/pm/vision-list.sh $ARGUMENTS
```

## Output Modes

**Simple Mode (`/pm:vision-list`):**
- Lists product visions and sub-visions
- Shows file names and GitHub links
- Basic organizational structure

**Tree Mode (`/pm:vision-list --tree`):**
- Hierarchical view of vision relationships
- Product visions with nested sub-visions
- Identifies orphaned sub-visions
- Clear parent-child structure

**Status Mode (`/pm:vision-list --status`):**
- Includes epic completion progress
- Shows percentage completion per vision
- Counts linked epics and their status
- Useful for project dashboards

## Information Displayed

For each vision:
- Vision name and title
- File location (`.claude/visions/<name>.md`)
- GitHub issue link (if exists)
- Progress metrics (in status mode)
- Parent-child relationships (in tree mode)

## Next Actions

After viewing visions:
- Create new vision: `/pm:vision-new <name>`
- Edit existing vision: `/pm:vision-edit <name>`
- Audit epic links: `/pm:vision-audit`
- Match epics to visions: `/pm:vision-match --epic <name>`