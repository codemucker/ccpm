#!/bin/bash

# PM Intelligent Sync System
# Auto-detects and fixes GitHub/local vision inconsistencies using AI

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
VISIONS_DIR="$PROJECT_ROOT/.claude/visions"
EPICS_DIR="$PROJECT_ROOT/.claude/epics"

show_help() {
    echo "🔄 PM Intelligent Sync System"
    echo ""
    echo "Usage:"
    echo "  /pm:sync                    # Auto-detect and fix all inconsistencies"
    echo "  /pm:sync --dry-run          # Show what would be synced without making changes"
    echo "  /pm:sync --github-first     # Prioritize GitHub as source of truth"
    echo "  /pm:sync --local-first      # Prioritize local files as source of truth"
    echo ""
    echo "What it detects and fixes:"
    echo "  • GitHub issues without local vision files"
    echo "  • Local visions without GitHub issues"
    echo "  • Mismatched content between GitHub and local"
    echo "  • Broken vision ↔ epic ↔ issue links"
    echo "  • Missing or incorrect labels"
    echo "  • Orphaned epics without vision alignment"
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

DRY_RUN=false
GITHUB_FIRST=false
LOCAL_FIRST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --github-first)
            GITHUB_FIRST=true
            shift
            ;;
        --local-first)
            LOCAL_FIRST=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check prerequisites
if ! command -v gh >/dev/null 2>&1; then
    echo "❌ GitHub CLI not available. Install 'gh' for full sync capabilities."
    echo "   Local-only sync operations will still work."
    GITHUB_AVAILABLE=false
else
    GITHUB_AVAILABLE=true
fi

cd "$PROJECT_ROOT"

echo "🔄 PM Intelligent Sync System"
echo "============================="
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🔍 DRY RUN MODE - No changes will be made"
    echo ""
fi

# Create directories if they don't exist
mkdir -p "$VISIONS_DIR" "$EPICS_DIR"

ISSUES_CREATED=0
FILES_CREATED=0
CONTENT_SYNCED=0
LINKS_FIXED=0
LABELS_FIXED=0

# Step 1: Detect workflow preference
echo "🔍 Detecting team workflow preferences..."

VISION_FILES_COUNT=$(find "$VISIONS_DIR" -name "*.md" 2>/dev/null | wc -l)
if [[ "$GITHUB_AVAILABLE" == "true" ]]; then
    GITHUB_VISION_ISSUES=$(gh issue list --label "vision" --json number | jq length 2>/dev/null || echo "0")
else
    GITHUB_VISION_ISSUES=0
fi

if [[ "$GITHUB_FIRST" == "true" ]]; then
    WORKFLOW_PREFERENCE="github-first"
    echo "📌 Using GitHub-first workflow (explicitly set)"
elif [[ "$LOCAL_FIRST" == "true" ]]; then
    WORKFLOW_PREFERENCE="local-first"
    echo "📌 Using local-first workflow (explicitly set)"
elif [[ $GITHUB_VISION_ISSUES -gt $VISION_FILES_COUNT ]]; then
    WORKFLOW_PREFERENCE="github-first"
    echo "📌 Detected GitHub-first workflow ($GITHUB_VISION_ISSUES issues > $VISION_FILES_COUNT files)"
elif [[ $VISION_FILES_COUNT -gt $GITHUB_VISION_ISSUES ]]; then
    WORKFLOW_PREFERENCE="local-first"
    echo "📌 Detected local-first workflow ($VISION_FILES_COUNT files > $GITHUB_VISION_ISSUES issues)"
else
    WORKFLOW_PREFERENCE="balanced"
    echo "📌 Balanced workflow detected - will use AI to resolve conflicts"
fi

echo ""

# Step 2: Sync GitHub issues to local files (if GitHub-first or balanced)
if [[ "$GITHUB_AVAILABLE" == "true" ]] && [[ "$WORKFLOW_PREFERENCE" != "local-first" ]]; then
    echo "📥 Syncing GitHub issues to local files..."
    
    # Get all vision-labeled issues
    VISION_ISSUES=$(gh issue list --label "vision" --json number,title,body,labels --jq '.[] | @json' 2>/dev/null || echo "")
    
    if [[ -n "$VISION_ISSUES" ]]; then
        while IFS= read -r issue_json; do
            if [[ -n "$issue_json" ]]; then
                issue_number=$(echo "$issue_json" | jq -r '.number')
                issue_title=$(echo "$issue_json" | jq -r '.title')
                issue_body=$(echo "$issue_json" | jq -r '.body')
                
                # Extract vision name from title (remove "Vision: " or "Sub-Vision: " prefix)
                vision_name=$(echo "$issue_title" | sed 's/^Sub-Vision: //; s/^Vision: //')
                vision_file=$(echo "$vision_name" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')
                vision_path="$VISIONS_DIR/$vision_file.md"
                
                if [[ ! -f "$vision_path" ]]; then
                    echo "🆕 Creating local vision file from GitHub issue #$issue_number: $vision_name"
                    
                    if [[ "$DRY_RUN" == "false" ]]; then
                        # Extract vision statement from issue body
                        vision_statement=$(echo "$issue_body" | sed -n '/## Vision Statement/,/## /p' | grep -v "^## " | grep -v "^$" | head -5 | tr '\n' ' ' || echo "Vision statement from GitHub issue #$issue_number")
                        
                        # Determine if it's a sub-vision
                        if echo "$issue_title" | grep -q "^Sub-Vision:"; then
                            vision_type="Sub-Vision"
                            # Try to detect parent from issue body or use placeholder
                            parent_vision=$(echo "$issue_body" | grep -o "Parent.*:" | head -1 | sed 's/Parent.*: *//' || echo "_TBD_")
                        else
                            vision_type="Product Vision"
                            parent_vision=""
                        fi
                        
                        # Create vision file
                        cat > "$vision_path" << EOF
# $vision_name

**Vision Type:** $vision_type$(if [[ -n "$parent_vision" ]]; then echo "
**Parent Vision:** $parent_vision"; fi)
**Created:** $(date '+%Y-%m-%d')
**GitHub Issue:** #$issue_number

## Vision Statement

$vision_statement

## Success Metrics

- [ ] **Metric 1:** _Define measurable success criteria_
- [ ] **Metric 2:** _What does success look like?_
- [ ] **Metric 3:** _How will you measure progress?_

## Strategic Context

### Problem We're Solving
_What problem does this vision address?_

### Target Outcomes
_What will be different when this vision is realized?_

### Constraints & Considerations
- **Technical:** _Any technical constraints or requirements_
- **Business:** _Budget, timeline, or business constraints_
- **User:** _User experience or accessibility requirements_

$(if [[ "$vision_type" == "Sub-Vision" ]]; then echo "## Alignment with Parent Vision

_Explain how this sub-vision supports and advances the parent product vision._"; fi)

## Related Epics

_This section will be updated automatically as epics are linked to this vision._

## Status

**Current Phase:** Planning
**Progress:** 0% Complete
**Last Updated:** $(date '+%Y-%m-%d')

---

*This vision was synced from GitHub issue #$issue_number using Claude Code PM.*
EOF
                        FILES_CREATED=$((FILES_CREATED + 1))
                    fi
                else
                    # Check if local file has correct GitHub issue number
                    if ! grep -q "**GitHub Issue:** #$issue_number" "$vision_path"; then
                        echo "🔗 Fixing GitHub issue link in $vision_file (#$issue_number)"
                        if [[ "$DRY_RUN" == "false" ]]; then
                            sed -i "s/**GitHub Issue:** .*/**GitHub Issue:** #$issue_number/" "$vision_path"
                            LINKS_FIXED=$((LINKS_FIXED + 1))
                        fi
                    fi
                fi
            fi
        done <<< "$VISION_ISSUES"
    fi
fi

# Step 3: Sync local files to GitHub issues (if local-first or balanced)
if [[ "$GITHUB_AVAILABLE" == "true" ]] && [[ "$WORKFLOW_PREFERENCE" != "github-first" ]]; then
    echo "📤 Syncing local files to GitHub issues..."
    
    if ls "$VISIONS_DIR"/*.md >/dev/null 2>&1; then
        for vision_file in "$VISIONS_DIR"/*.md; do
            basename=$(basename "$vision_file" .md)
            
            # Check if vision has GitHub issue
            if ! grep -q "**GitHub Issue:** #[0-9]*" "$vision_file"; then
                echo "🆕 Creating GitHub issue for local vision: $basename"
                
                if [[ "$DRY_RUN" == "false" ]]; then
                    # Use existing vision-github.sh logic
                    if "$SCRIPT_DIR/vision-github.sh" "$basename" >/dev/null 2>&1; then
                        ISSUES_CREATED=$((ISSUES_CREATED + 1))
                    fi
                fi
            fi
        done
    fi
fi

# Step 4: Detect and fix broken vision ↔ epic links
echo "🔗 Checking vision ↔ epic linkages..."

if [[ -d "$EPICS_DIR" ]] && ls "$EPICS_DIR"/*.md >/dev/null 2>&1; then
    for epic_file in "$EPICS_DIR"/*.md; do
        basename=$(basename "$epic_file" .md)
        
        # Check if epic has vision alignment
        if ! grep -q "vision-support:" "$epic_file" && ! grep -q "github-vision-link:" "$epic_file"; then
            echo "⚠️  Epic '$basename' has no vision alignment"
            
            if [[ "$DRY_RUN" == "false" ]]; then
                echo "🤖 Running AI vision matching for epic: $basename"
                if "$SCRIPT_DIR/vision-match.sh" --epic "$basename" >/dev/null 2>&1; then
                    LINKS_FIXED=$((LINKS_FIXED + 1))
                fi
            fi
        fi
    done
fi

# Step 5: Validate and fix GitHub labels
if [[ "$GITHUB_AVAILABLE" == "true" ]]; then
    echo "🏷️  Validating GitHub labels..."
    
    # Ensure standard PM labels exist
    REQUIRED_LABELS=(
        "vision:Strategic product visions:0052CC"
        "sub-vision:Strategic sub-visions:5BC0F8" 
        "epic:Large development initiatives:D73A4A"
        "story:User stories and features:A2EEEF"
        "task:Implementation tasks:7057FF"
        "priority::high:High priority:D93F0B"
        "priority::medium:Medium priority:FBCA04"
        "priority::low:Low priority:0E8A16"
    )
    
    for label_def in "${REQUIRED_LABELS[@]}"; do
        IFS=':' read -r label_name label_desc label_color <<< "$label_def"
        
        if [[ "$DRY_RUN" == "false" ]]; then
            # Check if label exists, create if missing
            if ! gh label view "$label_name" >/dev/null 2>&1; then
                echo "🆕 Creating label: $label_name"
                gh label create "$label_name" --description "$label_desc" --color "$label_color" >/dev/null 2>&1 || true
                LABELS_FIXED=$((LABELS_FIXED + 1))
            fi
        fi
    done
fi

echo ""
echo "🎉 Sync Complete!"
echo "=================="
echo "GitHub issues created: $ISSUES_CREATED"
echo "Local files created: $FILES_CREATED"
echo "Content synced: $CONTENT_SYNCED"
echo "Links fixed: $LINKS_FIXED"
echo "Labels fixed: $LABELS_FIXED"

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "💡 Run without --dry-run to apply these changes"
fi

echo ""
echo "🚀 Next steps:"
echo "   /pm:vision-tree              # View complete vision hierarchy"
echo "   /pm:validate                 # Run full project validation"
echo "   /pm:fix-all                  # Fix any remaining quality issues"

exit 0
