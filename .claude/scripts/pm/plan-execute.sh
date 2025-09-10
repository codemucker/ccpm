#!/bin/bash

# PM Plan Execution
# Execute plan.md with linear task completion

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
PLAN_FILE="$PROJECT_ROOT/plan.md"

show_help() {
    echo "🚀 PM Plan Execution"
    echo ""
    echo "Usage:"
    echo "  /pm:plan-execute        # Execute existing plan.md"
    echo ""
    echo "Note: This command should be run from Claude Code with Task tool"
    echo "      for proper LLM execution of fix tasks."
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ ! -f "$PLAN_FILE" ]]; then
    echo "❌ No plan.md found."
    echo ""
    echo "Create a fix plan first:"
    echo "   /pm:plan-fixes [path]"
    exit 1
fi

echo "🚀 Plan Execution Ready"
echo "======================"
echo ""
echo "📋 Plan file: $PLAN_FILE"
echo ""

# Show incomplete tasks
INCOMPLETE_TASKS=$(grep -c "^- \[ \]" "$PLAN_FILE" 2>/dev/null || echo 0)
COMPLETE_TASKS=$(grep -c "^- \[x\]" "$PLAN_FILE" 2>/dev/null || echo 0)

echo "📊 Task Status:"
echo "   Complete: $COMPLETE_TASKS"  
echo "   Remaining: $INCOMPLETE_TASKS"
echo ""

if [[ $INCOMPLETE_TASKS -eq 0 ]]; then
    echo "✅ All tasks complete! Running final validation..."
    
    # Run final validation
    if "$SCRIPT_DIR/validate.sh" >/dev/null 2>&1; then
        echo "🎉 All fixes successful - project validation passed!"
        
        # Archive the completed plan
        ARCHIVE_DIR="$PROJECT_ROOT/.claude/plans/completed"
        mkdir -p "$ARCHIVE_DIR"
        TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
        mv "$PLAN_FILE" "$ARCHIVE_DIR/plan_$TIMESTAMP.md"
        echo "📁 Plan archived to: .claude/plans/completed/plan_$TIMESTAMP.md"
    else
        echo "❌ Validation still failing. Check plan.md for missed items."
        exit 1
    fi
else
    echo "⚠️  This script provides plan status only."
    echo ""
    echo "🤖 To execute the plan with LLM:"
    echo "   Use Claude Code Task tool with this prompt:"
    echo ""
    echo '```'
    echo 'Execute the fix plan in plan.md. Work through each unchecked item'  
    echo 'in linear order. For each task:'
    echo ''
    echo '1. Read the task description'
    echo '2. Fix the issue (no explanations, just fix it)'
    echo '3. Mark task complete: - [x] **Fix:** ...'
    echo '4. Move to next task'
    echo ''
    echo 'After all tasks complete, run:'
    echo '- /pm:validate (must pass with zero errors)'
    echo '- Mark final validation items as complete'
    echo ''
    echo 'Do not provide status updates, explanations, or commentary.'
    echo 'Work silently and efficiently through the entire list.'
    echo '```'
    echo ""
    
    echo "🔧 Manual execution:"
    echo "   1. Open: $PLAN_FILE"
    echo "   2. Complete each [ ] item in order"  
    echo "   3. Mark as [x] when done"
    echo "   4. Run /pm:validate when finished"
fi

exit 0