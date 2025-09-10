---
allowed-tools: Task
---

# Vision Match

Use LLM to match epic descriptions to existing visions with smart linking.

## Usage
```
/pm:vision-match "<description>"     # Match description to existing visions
/pm:vision-match --epic <epic-name>  # Match epic's vision description
```

## Examples
```
/pm:vision-match "Improve mobile user experience"
/pm:vision-match --epic user-onboarding
```

## Instructions

Use Task tool to launch general-purpose agent for vision matching:

```yaml
Task:
  description: "Vision matching and linking"
  subagent_type: "general-purpose"
  prompt: |
    I need to match an epic or description to existing product visions.
    
    Execute the vision matching script:
    ```bash
    .claude/scripts/pm/vision-match.sh $ARGUMENTS
    ```
    
    The script will:
    1. Load all existing visions from .claude/visions/
    2. Use LLM analysis to find best matches
    3. Provide confidence scores and reasoning
    4. Offer auto-linking options
    5. Suggest new vision creation if no matches
    
    If epic mode (--epic flag):
    - Extract vision description from epic file
    - Match against existing visions
    - Offer to auto-link epic to matched vision
    - Update epic frontmatter and GitHub links
    
    Follow the script's interactive prompts and provide recommendations
    for maintaining vision-epic alignment.
    
    Report back with:
    - Matching results and confidence scores
    - Any successful links created
    - Recommendations for next steps
```

## Expected Outcomes

**For Description Matching:**
- List of matching visions with confidence scores
- Reasoning for each match
- Suggestions for creating new visions if needed

**For Epic Matching:**
- Best matching vision identified
- Option to auto-link epic to vision
- Updated epic files with proper vision references
- GitHub issue links maintained

## Follow-up Actions

After matching:
1. Verify links with `/pm:vision-audit <epic-name>`
2. Review vision alignment in epic
3. Continue with task breakdown: `/pm:epic-decompose <epic-name>`