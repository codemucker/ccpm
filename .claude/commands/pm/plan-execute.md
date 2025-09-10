---
allowed-tools: Task
---

# Plan Execute

Execute fix plan with linear task completion.

## Usage
```
/pm:plan-execute        # Execute existing plan.md
```

## Instructions

Use Task tool to execute the plan:

```yaml
Task:
  description: "Execute fix plan linearly"
  subagent_type: "general-purpose"  
  prompt: |
    Execute the fix plan in plan.md. Work through each unchecked item
    in linear order. For each task:
    
    1. Read the task description
    2. Fix the issue (no explanations, just fix it)
    3. Mark task complete: - [x] **Fix:** ...
    4. Move to next task
    
    After all tasks complete, run:
    - All linting must pass with zero errors
    - All tests must pass with zero failures  
    - Build must complete successfully
    - Application must start without errors
    
    Mark final validation items as complete when they pass.
    
    CRITICAL RULES:
    - Do not provide status updates or explanations during execution
    - Do not say "great job" or comment on progress
    - Work silently and efficiently through the entire list
    - Only report back when completely finished with all validation passing
    
    Execute now.
```

## Expected Behavior

**Silent Execution:**
- No progress commentary
- No explanations of what's being fixed
- No intermediate status reports
- Just linear task completion

**Completion Criteria:**
- All `- [ ]` items marked as `- [x]`
- All validation commands pass
- Full codebase health restored

## Post-Execution

When complete:
- Plan archived to `.claude/plans/completed/`
- Validation confirms zero errors
- Codebase ready for development

## Integration with Quality System

This command integrates with:
- `/pm:plan-fixes` - Creates the execution plan
- `/pm:validate` - Final verification
- `/pm:code-review` - Quality standards
- `/pm:anti-cheat` - Pattern detection

Creates a complete quality assurance workflow.