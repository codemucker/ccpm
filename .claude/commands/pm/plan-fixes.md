---
allowed-tools: Bash, Read, Write
---

# Plan Fixes

Analyze codebase with review + anti-cheat, then generate linear execution plan.

## Usage
```
/pm:plan-fixes [path]        # Analyze and create fix plan
/pm:plan-fixes               # Analyze entire project
```

## Examples
```
/pm:plan-fixes src/
/pm:plan-fixes
```

## Instructions

Execute the fix planning script:

```bash
.claude/scripts/pm/plan-fixes.sh $ARGUMENTS
```

## Process Flow

1. **Code Review Analysis**: Run `/pm:code-review` and extract violations
2. **Cheat Detection**: Run `/pm:anti-cheat` and extract patterns  
3. **Validation Check**: Run `/pm:validate` and extract failures
4. **Plan Generation**: Create `plan.md` with linear task list

## Generated Plan Structure

```markdown
# Fix Plan

## Quality Issues
- [ ] **Fix:** src/utils.js:15 - SRP violation
- [ ] **Fix:** src/auth.js:42 - DRY violation  

## Cheat Pattern Violations  
- [ ] **Remove cheat:** src/api.js:28 - Hardcoded response

## Validation Failures
- [ ] **Fix all linting errors**
- [ ] **Fix all test failures**
- [ ] **Fix all build errors**

## Final Validation
- [ ] **Run full linting** - Must pass with zero errors
- [ ] **Run all tests** - Must pass with zero failures
- [ ] **Run build** - Must complete successfully
- [ ] **Run application** - Must start without errors
```

## Key Features

- **No Commentary**: Plan contains only actionable tasks
- **Linear Order**: Execute tasks sequentially, no parallelization
- **Checkbox Format**: Clear completion tracking
- **Zero Tolerance**: All validation must pass completely

## Execution

After plan creation:
```bash
/pm:plan-execute    # Execute the plan
```

Or use Task tool with the generated plan for LLM execution.

## Integration

This replaces manual coordination of:
- `/pm:code-review`
- `/pm:anti-cheat`  
- `/pm:validate`

Into a single, executable fix workflow.