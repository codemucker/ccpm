---
allowed-tools: Bash, Read
---

# Vision Orphans

Show epics without vision links.

## Usage
```
/pm:vision-orphans
```

## Instructions

Execute the vision orphans script:

```bash
.claude/scripts/pm/vision-orphans.sh
```

## Purpose

Quickly identifies epics that lack strategic alignment:

- **Orphaned Epics**: No vision description filled out
- **Missing Links**: Epics not connected to any strategic theme
- **Technical Debt**: Work that needs strategic justification

## Output

Lists all epics missing vision alignment:

```
❌ user-authentication
❌ payment-processing  
❌ admin-dashboard

🔧 Fix suggestions:
   /pm:vision-match --epic user-authentication
   /pm:vision-match --epic payment-processing
   /pm:vision-match --epic admin-dashboard
```

## When to Use

- **Sprint Planning**: Before starting new work
- **Strategic Reviews**: Ensure all work supports business goals  
- **Regular Maintenance**: Weekly orphan checks
- **Before Releases**: Verify strategic alignment

Essential for maintaining vision-driven development discipline.