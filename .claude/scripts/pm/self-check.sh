#!/bin/bash

# PM Self-Check
# Automatically run quality checks, cheat detection, and validation on project

echo "🤖 PM SELF-CHECK INITIATED"
echo "=========================="

target_path="${1:-.}"
auto_fix="${2:---fix-on-fail}"
strict_mode="--strict"

echo "📁 Target: $target_path"
echo "🔧 Auto-fix enabled: ${auto_fix}"
echo "⚡ Running in strict mode"
echo ""

# Change to target directory
cd "$target_path" || exit 1

# Run intelligent project detection first
echo "🔍 Running intelligent project detection..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/project-detect.sh"

if ! load_cached_detection "$PWD"; then
    detect_project "$PWD"
    source "$CACHE_FILE"
fi

echo "📊 Project Analysis Complete:"
echo "  Types: ${PROJECT_TYPES[*]:-none}"
echo "  Languages: ${LANGUAGES[*]:-none}"
echo "  Build Tools: ${BUILD_TOOLS[*]:-none}"
echo "  Lint Tools: ${LINT_TOOLS[*]:-none}"
echo ""

# Step 1: Code Review
echo "🔍 STEP 1: COMPREHENSIVE CODE REVIEW"
echo "===================================="

if ! ".claude/scripts/pm/code-review.sh" "$target_path"; then
    echo ""
    echo "❌ CODE REVIEW FAILED - Quality issues detected"
    echo "   Fix all code quality issues before proceeding"
    echo "   Run: /pm:code-review to see detailed issues"
    exit 1
fi

echo ""
echo "✅ Code review passed - All quality standards met"

# Step 2: Cheat Detection
echo ""
echo "🕵️ STEP 2: CHEAT DETECTION"
echo "==========================="

if ! ".claude/scripts/pm/anti-cheat.sh" "$target_path"; then
    cheat_exit_code=$?
    echo ""
    echo "❌ CHEAT DETECTION FAILED"
    
    case $cheat_exit_code in
        1)
            echo "   Minor cheat patterns detected - Review and fix"
            ;;
        2)
            echo "   Significant cheat patterns detected - Major cleanup needed"
            ;;
        3)
            echo "   Extensive cheat patterns detected - Consider rewrite"
            ;;
    esac
    
    echo "   Run: /pm:anti-cheat to see detailed violations"
    exit $cheat_exit_code
fi

echo ""
echo "✅ Cheat detection passed - No cheat patterns detected"

# Step 3: Comprehensive Validation
echo ""
echo "🧪 STEP 3: COMPREHENSIVE VALIDATION" 
echo "==================================="

if ! ".claude/scripts/pm/validate.sh" "$target_path" $strict_mode $auto_fix; then
    echo ""
    echo "❌ VALIDATION FAILED"
    echo "   Critical issues preventing production readiness"
    echo "   Run: /pm:validate --strict --fix-on-fail to see details"
    exit 1
fi

echo ""
echo "✅ Validation passed - Project is production ready"

# Step 4: Generate Quality Report
echo ""
echo "📋 STEP 4: QUALITY REPORT GENERATION"
echo "===================================="

report_file="quality-report-$(date +%Y%m%d-%H%M%S).md"

cat > "$report_file" << EOF
# Quality Report
Generated: $(date)
Project: $target_path

## Summary
✅ **ALL QUALITY CHECKS PASSED**

### Code Review Results
- ✅ SOLID principles enforced
- ✅ DRY, KISS, ROCO, POLA, YAGNI, CLEAN standards met
- ✅ Test quality verified (GIVEN-WHEN-THEN, FIRST, MEANINGFUL)
- ✅ No quality violations detected

### Cheat Detection Results  
- ✅ No hardcoded responses found
- ✅ No simulation/fake logic detected
- ✅ No shortcuts or bypasses found
- ✅ No deceptive implementation patterns
- ✅ All code represents genuine implementations

### Validation Results
- ✅ All linting checks passed (zero tolerance)
- ✅ All tests passed with meaningful assertions
- ✅ All builds completed successfully
- ✅ Applications start and run correctly
- ✅ Project verified as production ready

## Quality Standards Applied
- **Production Code**: SOLID, DRY, KISS, ROCO, POLA, YAGNI, CLEAN
- **Test Code**: GIVEN-WHEN-THEN, FIRST, MEANINGFUL
- **Cheat Detection**: Comprehensive cheat pattern detection
- **Validation**: Zero tolerance for failures

## Conclusion
🏆 **PROJECT MEETS ALL PRODUCTION STANDARDS**

This codebase demonstrates:
- High code quality following industry best practices
- Authentic implementations without cheat patterns
- Test coverage with meaningful assertions
- Full operational validation with zero tolerance
- Production readiness verified through real execution

All claims of functionality have been actively verified.
EOF

echo "📄 Quality report generated: $report_file"

# Final Summary
echo ""
echo "🏆 SELF-CHECK COMPLETE: ALL SYSTEMS GO"
echo "======================================"
echo ""
echo "✅ Code Review: PASSED"
echo "✅ Cheat Detection: PASSED" 
echo "✅ Validation: PASSED"
echo "✅ Quality Report: GENERATED"
echo ""
echo "🎉 PROJECT VERIFIED AS PRODUCTION READY"
echo "🚀 All quality standards met"
echo "🔍 No cheat patterns detected"
echo "🧪 All functionality verified with real execution"
echo ""
echo "📋 Report available at: $report_file"

exit 0