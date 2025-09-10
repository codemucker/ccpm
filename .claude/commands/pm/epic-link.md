---
allowed-tools: Bash, Read, Write
---

# Epic Link

Link epics to visions with validation and interactive setup.

## Usage
```
/pm:epic-link <epic-name> <vision-name>    # Link epic to vision
/pm:epic-link --unlink <epic-name>         # Remove vision link
/pm:epic-link --show <epic-name>           # Show current links
```

## Examples
```
/pm:epic-link user-onboarding user-experience
/pm:epic-link --unlink user-onboarding  
/pm:epic-link --show user-onboarding
```

## Instructions

Execute the epic linking script:

```bash
.claude/scripts/pm/epic-link.sh $ARGUMENTS
```

## Linking Process

**For New Links:**
1. Validates epic and vision files exist
2. Shows vision information and type
3. Prompts for vision alignment description
4. Updates epic frontmatter and body sections
5. Links to GitHub issue if available
6. Confirms successful linking

**For Show Mode:**
1. Displays current vision description
2. Shows GitHub issue link status  
3. Validates link integrity
4. Provides next action suggestions

**For Unlink Mode:**
1. Removes vision description from epic
2. Clears GitHub issue links
3. Resets fields to placeholder values
4. Confirms removal

## Epic File Updates

The command updates these epic sections:

**Frontmatter:**
```yaml
vision-support: "Description of how epic supports vision"
github-vision-link: "#123"
```

**Body Section:**
```markdown
## Vision Alignment

**Vision-Support:** "Description text"
**GitHub-Vision-Link:** #123
```

## Validation Features

- Checks epic file exists before linking
- Validates vision file exists  
- Lists available visions if target not found
- Verifies GitHub issue links when possible
- Shows vision type (Product Vision vs Sub-Vision)

## Interactive Prompts

When linking, you'll be prompted for:
- Vision alignment description
- Confirmation of auto-linking
- Review of vision information

The description should explain:
- How the epic advances the vision
- What strategic value it provides  
- How it fits into the larger goals

## Integration with Workflow

**After PRD Parsing:**
```bash
/pm:prd-parse feature-name
/pm:epic-link feature-name vision-name  # Manual linking
# or
/pm:vision-match --epic feature-name    # Smart matching
```

**Before Task Breakdown:**
```bash
/pm:epic-link --show feature-name       # Verify alignment
/pm:epic-decompose feature-name         # Break into tasks
```

This ensures all epics maintain clear traceability to strategic visions throughout the development process.