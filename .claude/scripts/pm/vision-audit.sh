#!/bin/bash

# PM Vision Audit System
# Audits epic-vision alignment and maintains integrity of vision links

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
VISIONS_DIR="$PROJECT_ROOT/.claude/visions"
EPICS_DIR="$PROJECT_ROOT/.claude/epics"

show_help() {
    echo "🔍 PM Vision Audit"
    echo ""
    echo "Usage:"
    echo "  /pm:vision-audit                    # Audit all epics"
    echo "  /pm:vision-audit <epic-name>        # Audit specific epic"
    echo "  /pm:vision-audit --orphans          # Show epics without vision links"
    echo "  /pm:vision-audit --validate         # Validate all vision links"
    echo "  /pm:vision-audit --fix              # Auto-fix broken links where possible"
    echo ""
    echo "Examples:"
    echo "  /pm:vision-audit user-onboarding"
    echo "  /pm:vision-audit --orphans"
    echo "  /pm:vision-audit --fix"
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

MODE="all"
SPECIFIC_EPIC=""
AUTO_FIX=false

# Parse arguments
if [[ "$1" == "--orphans" ]]; then
    MODE="orphans"
elif [[ "$1" == "--validate" ]]; then
    MODE="validate"
elif [[ "$1" == "--fix" ]]; then
    MODE="fix"
    AUTO_FIX=true
elif [[ -n "$1" ]]; then
    MODE="specific"
    SPECIFIC_EPIC="$1"
fi

echo "🔍 Vision Audit Report"
echo "======================"
echo ""

# Check if epics and visions exist
if [[ ! -d "$EPICS_DIR" ]] || [[ -z "$(ls -A "$EPICS_DIR" 2>/dev/null)" ]]; then
    echo "❌ No epics found. Create epics first with /pm:prd-parse"
    exit 1
fi

TOTAL_EPICS=0
LINKED_EPICS=0
ORPHANED_EPICS=0
BROKEN_LINKS=0
ISSUES_FOUND=()
ORPHANED_LIST=()
BROKEN_LIST=()

# Audit function for a single epic
audit_epic() {
    local epic_name="$1"
    local epic_file="$2"
    
    ((TOTAL_EPICS++))
    
    # Check if epic has vision support field
    local vision_support=$(grep "^vision-support:" "$epic_file" 2>/dev/null | sed 's/^vision-support: *//' | sed 's/\[.*\]//' | tr -d '"' | xargs)
    local github_vision_link=$(grep "^github-vision-link:" "$epic_file" 2>/dev/null | sed 's/^github-vision-link: *//' | sed 's/\[.*\]//' | tr -d '"' | xargs)
    local body_vision_support=$(grep -A 1 "Vision-Support:" "$epic_file" 2>/dev/null | tail -1 | sed 's/^.*"//' | sed 's/".*$//' | xargs)
    
    # Use body vision support if frontmatter is empty
    if [[ -z "$vision_support" ]] || [[ "$vision_support" =~ ^\[.*\]$ ]]; then
        vision_support="$body_vision_support"
    fi
    
    local has_vision_description=false
    local has_github_link=false
    local github_link_valid=false
    
    # Check vision description
    if [[ -n "$vision_support" ]] && [[ "$vision_support" != "_TBD_" ]] && [[ ! "$vision_support" =~ ^\[.*\]$ ]]; then
        has_vision_description=true
    fi
    
    # Check GitHub vision link
    if [[ -n "$github_vision_link" ]] && [[ "$github_vision_link" != "_TBD_" ]] && [[ ! "$github_vision_link" =~ ^\[.*\]$ ]]; then
        has_github_link=true
        
        # Validate GitHub link exists
        if [[ "$github_vision_link" =~ ^#[0-9]+$ ]]; then
            # Check if GitHub issue exists (basic validation)
            if command -v gh >/dev/null 2>&1; then
                local issue_num=${github_vision_link#\#}
                if gh issue view "$issue_num" >/dev/null 2>&1; then
                    github_link_valid=true
                fi
            else
                # Assume valid if we can't check
                github_link_valid=true
            fi
        fi
    fi
    
    # Categorize epic
    if [[ "$has_vision_description" == "true" ]]; then
        ((LINKED_EPICS++))
        
        local status="✅ LINKED"
        local details=""
        
        if [[ "$has_github_link" == "true" ]]; then
            if [[ "$github_link_valid" == "true" ]]; then
                details=" → $github_vision_link"
            else
                details=" → $github_vision_link ❌ (broken link)"
                ((BROKEN_LINKS++))
                BROKEN_LIST+=("$epic_name: $github_vision_link")
            fi
        else
            details=" (no GitHub link)"
        fi
        
        echo "   $status $epic_name$details"
        if [[ "$MODE" == "all" ]] || [[ "$MODE" == "specific" ]]; then
            echo "      Vision: $vision_support"
        fi
    else
        ((ORPHANED_EPICS++))
        ORPHANED_LIST+=("$epic_name")
        echo "   ❌ ORPHANED $epic_name (no vision description)"
    fi
}

# Main audit logic
case "$MODE" in
    "specific")
        if [[ -z "$SPECIFIC_EPIC" ]]; then
            echo "❌ Epic name required"
            exit 1
        fi
        
        epic_file="$EPICS_DIR/$SPECIFIC_EPIC/epic.md"
        if [[ ! -f "$epic_file" ]]; then
            echo "❌ Epic not found: $SPECIFIC_EPIC"
            exit 1
        fi
        
        echo "📋 Auditing Epic: $SPECIFIC_EPIC"
        echo ""
        audit_epic "$SPECIFIC_EPIC" "$epic_file"
        
        # Try to match vision if orphaned
        if [[ $ORPHANED_EPICS -gt 0 ]]; then
            echo ""
            echo "🤖 Attempting automatic vision matching..."
            if "$SCRIPT_DIR/vision-match.sh" --epic "$SPECIFIC_EPIC"; then
                echo "✅ Vision matching suggestions provided"
            else
                echo "⚠️  No suitable vision matches found"
            fi
        fi
        ;;
        
    "orphans")
        echo "📋 Orphaned Epics (no vision alignment):"
        echo ""
        
        for epic_dir in "$EPICS_DIR"/*/; do
            if [[ -d "$epic_dir" ]]; then
                epic_name=$(basename "$epic_dir")
                epic_file="$epic_dir/epic.md"
                
                if [[ -f "$epic_file" ]]; then
                    vision_support=$(grep "^vision-support:" "$epic_file" 2>/dev/null | sed 's/^vision-support: *//' | sed 's/\[.*\]//' | tr -d '"' | xargs)
                    body_vision_support=$(grep -A 1 "Vision-Support:" "$epic_file" 2>/dev/null | tail -1 | sed 's/^.*"//' | sed 's/".*$//' | xargs)
                    
                    if [[ -z "$vision_support" ]] || [[ "$vision_support" =~ ^\[.*\]$ ]]; then
                        vision_support="$body_vision_support"
                    fi
                    
                    if [[ -z "$vision_support" ]] || [[ "$vision_support" == "_TBD_" ]] || [[ "$vision_support" =~ ^\[.*\]$ ]]; then
                        echo "   ❌ $epic_name"
                        ORPHANED_LIST+=("$epic_name")
                        ((ORPHANED_EPICS++))
                    fi
                    ((TOTAL_EPICS++))
                fi
            fi
        done
        
        if [[ ${#ORPHANED_LIST[@]} -eq 0 ]]; then
            echo "   ✅ No orphaned epics found!"
        else
            echo ""
            echo "🔧 Fix suggestions:"
            for orphan in "${ORPHANED_LIST[@]}"; do
                echo "   /pm:vision-match --epic $orphan"
            done
        fi
        ;;
        
    "validate"|"all"|"fix")
        echo "📋 All Epics Vision Alignment:"
        echo ""
        
        for epic_dir in "$EPICS_DIR"/*/; do
            if [[ -d "$epic_dir" ]]; then
                epic_name=$(basename "$epic_dir")
                epic_file="$epic_dir/epic.md"
                
                if [[ -f "$epic_file" ]]; then
                    audit_epic "$epic_name" "$epic_file"
                fi
            fi
        done
        
        echo ""
        echo "📊 Summary:"
        echo "   Total Epics: $TOTAL_EPICS"
        echo "   Linked to Vision: $LINKED_EPICS"
        echo "   Orphaned: $ORPHANED_EPICS"
        echo "   Broken Links: $BROKEN_LINKS"
        
        if [[ $ORPHANED_EPICS -gt 0 ]]; then
            echo ""
            echo "🚨 Issues Found:"
            echo ""
            echo "   Orphaned Epics:"
            for orphan in "${ORPHANED_LIST[@]}"; do
                echo "     • $orphan"
            done
            
            if [[ "$AUTO_FIX" == "true" ]]; then
                echo ""
                echo "🔧 Auto-fixing orphaned epics..."
                for orphan in "${ORPHANED_LIST[@]}"; do
                    echo "   Matching $orphan..."
                    "$SCRIPT_DIR/vision-match.sh" --epic "$orphan" || true
                done
            fi
        fi
        
        if [[ $BROKEN_LINKS -gt 0 ]]; then
            echo ""
            echo "   Broken GitHub Links:"
            for broken in "${BROKEN_LIST[@]}"; do
                echo "     • $broken"
            done
        fi
        
        if [[ $ORPHANED_EPICS -eq 0 ]] && [[ $BROKEN_LINKS -eq 0 ]]; then
            echo ""
            echo "🎉 All epics are properly linked to visions!"
        fi
        ;;
esac

# Return appropriate exit code
if [[ $ORPHANED_EPICS -gt 0 ]] || [[ $BROKEN_LINKS -gt 0 ]]; then
    exit 1
else
    exit 0
fi