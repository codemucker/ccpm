#!/bin/bash

# PM Fix All - Complete quality fix workflow
# Runs review + anti-cheat + validation, then creates and executes fix plan

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    echo "🔧 PM Fix All - Complete Quality Fix Workflow"
    echo ""
    echo "Usage:"
    echo "  /pm:fix-all [path]       # Analyze, plan, and prepare fixes"
    echo ""
    echo "Examples:"
    echo "  /pm:fix-all src/"
    echo "  /pm:fix-all"
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

TARGET_PATH="${1:-.}"

echo "🔧 Complete Quality Fix Workflow"
echo "================================"
echo ""
echo "Target: $TARGET_PATH"
echo ""

# Step 1: Create fix plan
echo "📋 Creating fix plan..."
if "$SCRIPT_DIR/plan-fixes.sh" "$TARGET_PATH"; then
    echo "✅ Fix plan created: plan.md"
else
    echo "❌ Failed to create fix plan"
    exit 1
fi

echo ""
echo "🚀 Fix plan ready for execution."
echo ""
echo "🤖 Next step - Execute with LLM:"
echo ""
echo "Use Task tool with this prompt:"
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
echo 'After all tasks complete, run final validation:'
echo '- Run /pm:validate - must pass with zero errors'
echo '- Mark final validation items as complete'
echo ''
echo 'CRITICAL RULES:'
echo '- Do not provide status updates or explanations during execution'
echo '- Do not say "great job" or comment on progress' 
echo '- Work silently and efficiently through the entire list'
echo '- Only report back when completely finished with validation passing'
echo ''
echo 'Execute the plan now.'
echo '```'
echo ""

# Show plan summary
if [[ -f "plan.md" ]]; then
    TOTAL_TASKS=$(grep -c "^- \[ \]" "plan.md" 2>/dev/null || echo 0)
    echo "📊 Fix tasks to complete: $TOTAL_TASKS"
    echo ""
    echo "📋 Plan summary:"
    grep "^- \[ \]" "plan.md" | head -5
    if [[ $TOTAL_TASKS -gt 5 ]]; then
        echo "   ... and $((TOTAL_TASKS - 5)) more tasks"
    fi
fi

echo ""
echo "🔧 Manual alternative:"
echo "   /pm:plan-execute    # Check plan status"
echo "   Open plan.md and complete each task manually"

exit 0