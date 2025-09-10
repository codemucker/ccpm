---
allowed-tools: Bash, Read, Write
---

# Vision New Sub

Create new sub-vision with GitHub integration.

## Usage
```
/pm:vision-new-sub <sub-vision-name>
```

## Examples
```
/pm:vision-new-sub user-experience
/pm:vision-new-sub data-insights
/pm:vision-new-sub platform-scalability
```

## Instructions

Execute the sub-vision creation script:

```bash
.claude/scripts/pm/vision-new-sub.sh $ARGUMENTS
```

The script will:

1. **Validate Parent Vision**: Ensure at least one product vision exists
2. **Create Sub-Vision File**: Generate structured sub-vision document in `.claude/visions/`
3. **Parent Selection**: Prompt to select which product vision this supports
4. **GitHub Integration**: Optionally create GitHub issue for sub-vision tracking
5. **Template Setup**: Provide complete sub-vision structure with strategic context

## Sub-Vision Purpose

Sub-visions are **strategic themes** that:
- Break down product visions into focused areas
- Provide clearer context for epic planning
- Enable better prioritization and resource allocation
- Bridge high-level vision and specific implementation

## Post-Creation Actions

After sub-vision is created:
1. Edit sub-vision details: `/pm:vision-edit <sub-vision-name>`
2. Link epics to this sub-vision: `/pm:vision-match --epic <epic-name>`
3. View hierarchy: `/pm:vision-list --tree`

## Strategic Flow

```
Product Vision: "Marketplace Platform"
├── Sub-Vision: "User Experience Excellence" 
├── Sub-Vision: "Data-Driven Insights"
└── Sub-Vision: "Platform Scalability"
```

Each sub-vision then has epics that advance its strategic theme while supporting the overall product vision.