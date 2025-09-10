#!/bin/bash

# PM Fix Planning System
# Runs review + anti-cheat, then generates linear execution plan

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
PLAN_FILE="$PROJECT_ROOT/plan.md"

show_help() {
    echo "🔧 PM Fix Planning"
    echo ""
    echo "Usage:"
    echo "  /pm:plan-fixes [path]        # Analyze and create fix plan"
    echo "  /pm:plan-fixes --execute     # Execute existing plan.md"
    echo ""
    echo "Examples:"
    echo "  /pm:plan-fixes src/"
    echo "  /pm:plan-fixes"
    echo "  /pm:plan-fixes --execute"
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ "$1" == "--execute" ]]; then
    if [[ ! -f "$PLAN_FILE" ]]; then
        echo "❌ No plan.md found. Run /pm:plan-fixes first."
        exit 1
    fi
    
    echo "🚀 Executing plan.md..."
    echo ""
    
    # Execute the plan using Task tool (this would be called from Claude Code)
    echo "Plan file exists at: $PLAN_FILE"
    echo "Use Task tool to execute the plan step by step."
    exit 0
fi

TARGET_PATH="${1:-.}"

echo "🔍 Analyzing codebase for issues..."
echo ""

# Create temporary files for analysis results
REVIEW_TEMP="/tmp/pm_review_$$.txt"
CHEAT_TEMP="/tmp/pm_cheat_$$.txt"
VALIDATE_TEMP="/tmp/pm_validate_$$.txt"

# Run code review
echo "📋 Running code review..."
"$SCRIPT_DIR/code-review.sh" "$TARGET_PATH" > "$REVIEW_TEMP" 2>&1 || true

# Run anti-cheat detection  
echo "🎭 Running cheat detection..."
"$SCRIPT_DIR/anti-cheat.sh" "$TARGET_PATH" > "$CHEAT_TEMP" 2>&1 || true

# Run validation to get current state
echo "🧪 Running validation..."
"$SCRIPT_DIR/validate.sh" > "$VALIDATE_TEMP" 2>&1 || true

echo ""
echo "🔧 Generating fix plan..."

# Create the plan.md file
cat > "$PLAN_FILE" << 'EOF'
# Fix Plan

Execute these fixes in linear order. No explanations, no status updates, just fix each item sequentially.

## Quality Issues

EOF

# Extract issues from code review
echo "### Code Review Violations" >> "$PLAN_FILE"
echo "" >> "$PLAN_FILE"

if grep -q "🚨 QUALITY VIOLATIONS DETECTED" "$REVIEW_TEMP"; then
    sed -n '/🚨 QUALITY VIOLATIONS DETECTED/,/^$/p' "$REVIEW_TEMP" | \
    grep -E "(📍 File:|❌ Issue:|🔧 Remediation:)" | \
    sed 's/📍 File:/- [ ] **Fix:** /' | \
    sed 's/❌ Issue://' | \
    sed 's/🔧 Remediation://' | \
    sed 's/^[[:space:]]*/  /' >> "$PLAN_FILE"
else
    echo "- [ ] No code review violations found" >> "$PLAN_FILE"
fi

echo "" >> "$PLAN_FILE"

# Extract cheat patterns
echo "### Cheat Pattern Violations" >> "$PLAN_FILE"
echo "" >> "$PLAN_FILE"

if grep -q "🚨 CHEAT PATTERN DETECTED" "$CHEAT_TEMP"; then
    sed -n '/🚨 CHEAT PATTERN DETECTED/,/^$/p' "$CHEAT_TEMP" | \
    grep -E "(📍 File:|🎭 Pattern:|🔧 Required Fix:)" | \
    sed 's/📍 File:/- [ ] **Remove cheat:** /' | \
    sed 's/🎭 Pattern://' | \
    sed 's/🔧 Required Fix://' | \
    sed 's/^[[:space:]]*/  /' >> "$PLAN_FILE"
else
    echo "- [ ] No cheat patterns detected" >> "$PLAN_FILE"  
fi

echo "" >> "$PLAN_FILE"

# Extract validation failures
echo "### Validation Failures" >> "$PLAN_FILE"
echo "" >> "$PLAN_FILE"

# Parse linting errors
if grep -q "❌.*lint" "$VALIDATE_TEMP" || grep -q "LINT.*FAILED" "$VALIDATE_TEMP"; then
    echo "- [ ] **Fix all linting errors**" >> "$PLAN_FILE"
    sed -n '/lint/,/^$/p' "$VALIDATE_TEMP" | \
    grep -E "error|Error|ERROR" | \
    head -10 | \
    sed 's/^/  - /' >> "$PLAN_FILE"
    echo "" >> "$PLAN_FILE"
fi

# Parse test failures  
if grep -q "❌.*test" "$VALIDATE_TEMP" || grep -q "TEST.*FAILED" "$VALIDATE_TEMP"; then
    echo "- [ ] **Fix all test failures**" >> "$PLAN_FILE"
    sed -n '/test/,/^$/p' "$VALIDATE_TEMP" | \
    grep -E "FAIL|fail|Error|error" | \
    head -10 | \
    sed 's/^/  - /' >> "$PLAN_FILE"
    echo "" >> "$PLAN_FILE"
fi

# Parse build failures
if grep -q "❌.*build" "$VALIDATE_TEMP" || grep -q "BUILD.*FAILED" "$VALIDATE_TEMP"; then
    echo "- [ ] **Fix all build errors**" >> "$PLAN_FILE"  
    sed -n '/build/,/^$/p' "$VALIDATE_TEMP" | \
    grep -E "error|Error|ERROR" | \
    head -10 | \
    sed 's/^/  - /' >> "$PLAN_FILE"
    echo "" >> "$PLAN_FILE"
fi

# Add final validation steps
cat >> "$PLAN_FILE" << 'EOF'

## Final Validation

- [ ] **Run full linting** - All linting must pass with zero errors
- [ ] **Run all tests** - All tests must pass with zero failures  
- [ ] **Run build** - Build must complete successfully
- [ ] **Run application** - Application must start and run without errors
- [ ] **Verify no regressions** - Confirm all functionality works as expected

## Execution Notes

Execute each item in order. Do not skip items. Do not provide status updates or explanations during execution. Move linearly through the list until all items are complete and all validation passes.

Mark each item as complete: `- [x] **Fix:** Description`

EOF

# Clean up temp files
rm -f "$REVIEW_TEMP" "$CHEAT_TEMP" "$VALIDATE_TEMP"

echo "✅ Fix plan created: plan.md"
echo ""

# Show summary of issues found
QUALITY_ISSUES=$(grep -c "🚨 QUALITY VIOLATIONS DETECTED" "$PLAN_FILE" 2>/dev/null || echo 0)
CHEAT_ISSUES=$(grep -c "🚨 CHEAT PATTERN DETECTED" "$PLAN_FILE" 2>/dev/null || echo 0)  
VALIDATION_ISSUES=$(grep -c "❌.*FAILED" "$PLAN_FILE" 2>/dev/null || echo 0)
TOTAL_TASKS=$(grep -c "^- \[ \]" "$PLAN_FILE" 2>/dev/null || echo 0)

echo "📊 Issues Found:"
echo "   Quality violations: $QUALITY_ISSUES"
echo "   Cheat patterns: $CHEAT_ISSUES"
echo "   Validation failures: $VALIDATION_ISSUES"
echo "   Total fix tasks: $TOTAL_TASKS"

echo ""
echo "🚀 Next steps:"
echo "   1. Review plan.md"
echo "   2. Execute: /pm:plan-execute"
echo "   3. Or use Task tool to run the plan"

exit 0