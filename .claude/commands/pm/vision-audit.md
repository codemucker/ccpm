---
allowed-tools: Bash, Read
---

# Vision Audit

Audit epic-vision alignment and maintain integrity of vision links.

## Usage
```
/pm:vision-audit                    # Audit all epics
/pm:vision-audit <epic-name>        # Audit specific epic
/pm:vision-audit --orphans          # Show epics without vision links
/pm:vision-audit --validate         # Validate all vision links
/pm:vision-audit --fix              # Auto-fix broken links where possible
```

## Examples
```
/pm:vision-audit user-onboarding
/pm:vision-audit --orphans
/pm:vision-audit --fix
```

## Instructions

Execute the vision audit script:

```bash
.claude/scripts/pm/vision-audit.sh $ARGUMENTS
```

## Audit Categories

**Linked Epics:**
- Have vision description in frontmatter or body
- May have GitHub issue links to visions
- Links are validated if GitHub CLI available

**Orphaned Epics:**
- Missing vision description
- No alignment with product strategy
- Need immediate attention

**Broken Links:**
- Have GitHub links that don't exist
- References to deleted or invalid issues
- Require manual correction

## Output Information

For each epic, the audit shows:
- ✅ **LINKED**: Epic has proper vision alignment
- ❌ **ORPHANED**: Epic lacks vision description
- Vision description text
- GitHub issue link status
- Link validation results

**Summary Statistics:**
- Total epics analyzed
- Number linked to visions
- Orphaned epic count
- Broken link count

## Auto-Fix Capabilities

When using `--fix` flag:
- Attempts automatic vision matching for orphaned epics
- Runs `/pm:vision-match --epic <name>` for each orphan
- Provides interactive linking options
- Updates epic files with proper references

## Remediation Workflow

For orphaned epics:
1. Run `/pm:vision-match --epic <epic-name>`
2. Review suggested vision matches
3. Link epic to appropriate vision
4. Re-run audit to verify fixes

For broken links:
1. Check if GitHub issue still exists
2. Update epic with correct issue number
3. Or remove broken link if vision was deleted

## Integration with Development Flow

**Before Starting Epic Work:**
```bash
/pm:vision-audit <epic-name>  # Ensure proper alignment
```

**During Sprint Planning:**
```bash
/pm:vision-audit --orphans    # Find unaligned work
```

**Regular Maintenance:**
```bash
/pm:vision-audit --validate   # Check all links
/pm:vision-audit --fix        # Auto-repair issues
```

This ensures all development work traces back to strategic visions.