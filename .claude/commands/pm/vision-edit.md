---
allowed-tools: Bash, Read
---

# Vision Edit

Edit vision files with validation.

## Usage
```
/pm:vision-edit <vision-name>     # Edit vision file
```

## Examples
```
/pm:vision-edit marketplace-platform
/pm:vision-edit user-experience
```

## Instructions

Execute the vision edit script:

```bash
.claude/scripts/pm/vision-edit.sh $ARGUMENTS
```

## Editor Selection

The script automatically selects an editor in this order:
1. `$EDITOR` environment variable
2. VS Code (`code`)
3. Nano (`nano`)
4. Vi (`vi`)

## Vision File Structure

When editing, maintain this structure:

```markdown
# Vision Name

**Vision Type:** Product Vision | Sub-Vision
**Parent Vision:** (if sub-vision)
**Created:** YYYY-MM-DD
**GitHub Issue:** #123

## Vision Statement
Clear, compelling vision statement

## Success Metrics
- [ ] Measurable criteria
- [ ] What success looks like
- [ ] How to measure progress

## Strategic Context
### Problem We're Solving
### Target Outcomes  
### Constraints & Considerations

## Related Epics
(Updated automatically)

## Status
**Current Phase:** Planning | Development | Complete
**Progress:** X% Complete
**Last Updated:** YYYY-MM-DD
```

## Post-Edit Actions

After editing:
1. **Optional Audit**: Run vision audit to check epic links
2. **View Changes**: See updated vision in hierarchy
3. **Update Links**: Match epics to updated vision

## Integration Points

Vision edits may require:
- Re-matching epics if vision focus changed
- Updating related sub-visions or parent visions
- Syncing changes to GitHub issues
- Notifying team of strategic changes

Use `/pm:vision-audit` after significant changes to ensure all epics remain properly aligned.