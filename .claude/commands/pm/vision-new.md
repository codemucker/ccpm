---
allowed-tools: Bash, Read, Write
---

# Vision New

Create new product vision or sub-vision with GitHub integration.

## Usage
```
/pm:vision-new <vision-name>           # Create product vision
/pm:vision-new <vision-name> --sub     # Create sub-vision
```

## Examples
```
/pm:vision-new marketplace-platform
/pm:vision-new user-experience --sub
```

## Instructions

Execute the vision creation script:

```bash
.claude/scripts/pm/vision-new.sh $ARGUMENTS
```

The script will:

1. **Create Vision File**: Generate structured vision document in `.claude/visions/`
2. **GitHub Integration**: Optionally create GitHub issue for vision tracking
3. **Validation**: Ensure proper parent-child relationships for sub-visions
4. **Template Setup**: Provide complete vision structure with all required sections

## Post-Creation Actions

After vision is created:
1. Edit vision details as needed: `/pm:vision-edit <vision-name>`
2. Create PRDs that reference this vision: `/pm:prd-new <name> --vision <vision-name>`
3. View all visions: `/pm:vision-list --tree`

## Important Notes

- Product visions should be created before sub-visions
- Sub-visions require existing product vision as parent
- GitHub issue creation requires authenticated `gh` CLI
- Vision files are stored locally in `.claude/visions/`
- Use descriptive, URL-friendly names for visions