---
allowed-tools: Task
---

# Fix All

Complete quality fix workflow - analyze, plan, and execute fixes.

## Usage
```
/pm:fix-all [path]       # Analyze, plan, and prepare fixes
/pm:fix-all              # Fix entire project
```

## Examples
```
/pm:fix-all src/
/pm:fix-all
```

## Instructions

The script will:
1. Run quality analysis (review + anti-cheat + validation)
2. Generate `plan.md` with linear task list
3. Provide execution instructions

Then use Task tool to execute the plan:

```yaml
Task:
  description: "Execute complete fix plan"
  subagent_type: "general-purpose"  
  prompt: |
    Execute the fix plan in plan.md. Work through each unchecked item
    in linear order. For each task:
    
    1. Read the task description
    2. Fix the issue (no explanations, just fix it)
    3. Mark task complete: - [x] **Fix:** ...
    4. Move to next task
    
    After all tasks complete, run final validation:
    - Run /pm:validate - must pass with zero errors
    - Mark final validation items as complete
    
    CRITICAL RULES:
    - Do not provide status updates or explanations during execution
    - Do not say "great job" or comment on progress
    - Work silently and efficiently through the entire list
    - Only report back when completely finished with validation passing
    
    Execute the plan now.
```

## Quality Standards Applied

The fix plan addresses:

**Code Review Issues:**
- SOLID principles violations
- DRY (Don't Repeat Yourself) violations  
- KISS (Keep It Simple) violations
- Code organization and naming issues

**Cheat Pattern Detection:**
- Hardcoded responses that should be computed
- Fake intelligence or simulation patterns
- Shortcuts and bypass logic
- Mock implementations in production code

**Validation Failures:**
- Linting errors (zero tolerance)
- Test failures (all must pass)
- Build errors (must complete successfully)
- Runtime issues (application must start)

## Linear Execution Model

The system creates a **linear task list** that:
- Executes fixes in dependency order
- Requires completion before moving to next item
- Ends with comprehensive validation
- Archives completed plan when done

## Integration

This command combines:
- `/pm:code-review` - Quality analysis
- `/pm:anti-cheat` - Pattern detection  
- `/pm:validate` - Comprehensive validation
- `/pm:plan-fixes` - Plan generation
- Task tool execution - Automated fixes

Into a single, complete quality assurance workflow.