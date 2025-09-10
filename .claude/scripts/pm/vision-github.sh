#!/bin/bash

# PM Vision GitHub Integration
# Creates GitHub issues for existing visions that don't have them yet

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
VISIONS_DIR="$PROJECT_ROOT/.claude/visions"

show_help() {
    echo "🔗 PM Vision GitHub Integration"
    echo ""
    echo "Usage:"
    echo "  /pm:vision-github                    # Create issues for all visions missing them"
    echo "  /pm:vision-github <vision-name>     # Create issue for specific vision"
    echo "  /pm:vision-github --list             # List visions and their GitHub status"
    echo ""
    echo "Examples:"
    echo "  /pm:vision-github                    # Auto-create missing issues"
    echo "  /pm:vision-github marketplace        # Create issue for marketplace vision"
    echo "  /pm:vision-github --list             # Show vision → issue mapping"
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Check if GitHub CLI is available
if ! command -v gh >/dev/null 2>&1; then
    echo "❌ GitHub CLI not available. Install 'gh' to create issues automatically."
    echo ""
    echo "Installation:"
    echo "  # Ubuntu/Debian: sudo apt install gh"
    echo "  # macOS: brew install gh"
    echo "  # Windows: winget install GitHub.cli"
    exit 1
fi

# Ensure visions directory exists
if [[ ! -d "$VISIONS_DIR" ]]; then
    echo "❌ No visions directory found. Create a vision first:"
    echo "   /pm:vision-new <name>"
    exit 1
fi

cd "$PROJECT_ROOT"

# List visions and their GitHub status
if [[ "$1" == "--list" ]]; then
    echo "📋 Vision GitHub Status"
    echo "======================"
    echo ""
    
    if ! ls "$VISIONS_DIR"/*.md >/dev/null 2>&1; then
        echo "No visions found in $VISIONS_DIR"
        exit 0
    fi
    
    for vision_file in "$VISIONS_DIR"/*.md; do
        basename=$(basename "$vision_file" .md)
        title=$(grep "^# " "$vision_file" | head -1 | sed 's/^# //' || echo "$basename")
        github_line=$(grep "**GitHub Issue:**" "$vision_file" || echo "**GitHub Issue:** _TBD_")
        issue_number=$(echo "$github_line" | grep -o '#[0-9]*' || echo "_TBD_")
        vision_type=$(grep "**Vision Type:**" "$vision_file" | sed 's/**Vision Type:** //' || echo "Unknown")
        
        if [[ "$issue_number" == "_TBD_" ]]; then
            echo "❌ $basename: $title ($vision_type) - No GitHub issue"
        else
            echo "✅ $basename: $title ($vision_type) - $issue_number"
        fi
    done
    exit 0
fi

create_issue_for_vision() {
    local vision_file="$1"
    local vision_path="$VISIONS_DIR/$vision_file.md"
    
    if [[ ! -f "$vision_path" ]]; then
        echo "❌ Vision '$vision_file' not found at: $vision_path"
        return 1
    fi
    
    # Check if already has GitHub issue
    if grep -q "**GitHub Issue:** #[0-9]*" "$vision_path"; then
        issue_number=$(grep "**GitHub Issue:**" "$vision_path" | grep -o '#[0-9]*')
        echo "✅ Vision '$vision_file' already has GitHub issue: $issue_number"
        return 0
    fi
    
    # Extract vision details
    vision_name=$(grep "^# " "$vision_path" | head -1 | sed 's/^# //' || echo "$vision_file")
    vision_type=$(grep "**Vision Type:**" "$vision_path" | sed 's/**Vision Type:** //' || echo "Product Vision")
    vision_statement=$(sed -n '/## Vision Statement/,/## /p' "$vision_path" | grep -v "^## " | grep -v "^$" | head -5 | tr '\n' ' ' || echo "No vision statement found")
    
    echo "🚀 Creating GitHub issue for: $vision_name"
    
    # Prepare issue body
    ISSUE_BODY=$(cat << EOI
## Vision Overview

This is a $(echo "$vision_type" | tr '[:upper:]' '[:lower:]') that provides strategic direction for development efforts.

**📁 Local File:** \`.claude/visions/$vision_file.md\`

## Vision Statement

$vision_statement

## Purpose

This issue tracks the overall progress and discussion for this vision. Individual epics will reference this issue to maintain strategic alignment.

## Related Work

- [ ] Epic tracking and progress updates will appear here
- [ ] Cross-references will be maintained automatically by ccpm

---

🤖 *This issue was created by Claude Code PM vision system*
EOI
)
    
    # Create the issue
    local issue_title="Vision: $vision_name"
    if [[ "$vision_type" == "Sub-Vision" ]]; then
        issue_title="Sub-Vision: $vision_name"
    fi
    
    ISSUE_NUMBER=$(gh issue create \
        --title "$issue_title" \
        --body "$ISSUE_BODY" \
        --label "vision$(if [[ "$vision_type" == "Sub-Vision" ]]; then echo ",sub-vision"; fi)" \
        | grep -o '#[0-9]*' | tr -d '#')
    
    if [[ -n "$ISSUE_NUMBER" ]]; then
        echo "✅ GitHub issue #$ISSUE_NUMBER created"
        
        # Update the vision file with GitHub issue number
        sed -i "s/**GitHub Issue:** _TBD_/**GitHub Issue:** #$ISSUE_NUMBER/" "$vision_path"
        
        echo "🔗 Vision linked to GitHub issue #$ISSUE_NUMBER"
        return 0
    else
        echo "❌ Failed to create GitHub issue for $vision_file"
        return 1
    fi
}

# Handle specific vision
if [[ -n "$1" ]]; then
    create_issue_for_vision "$1"
    exit $?
fi

# Handle all visions without GitHub issues
echo "🔍 Scanning for visions without GitHub issues..."
echo ""

if ! ls "$VISIONS_DIR"/*.md >/dev/null 2>&1; then
    echo "No visions found in $VISIONS_DIR"
    exit 0
fi

CREATED_COUNT=0
SKIPPED_COUNT=0

for vision_file in "$VISIONS_DIR"/*.md; do
    basename=$(basename "$vision_file" .md)
    
    if grep -q "**GitHub Issue:** #[0-9]*" "$vision_file"; then
        echo "⏭️  Skipping $basename (already has GitHub issue)"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    else
        if create_issue_for_vision "$basename"; then
            CREATED_COUNT=$((CREATED_COUNT + 1))
        fi
        echo ""
    fi
done

echo "🎉 GitHub Issue Creation Complete"
echo "================================="
echo "Created: $CREATED_COUNT"
echo "Skipped: $SKIPPED_COUNT"

if [[ $CREATED_COUNT -gt 0 ]]; then
    echo ""
    echo "💡 Next steps:"
    echo "   - View issues: gh issue list --label vision"
    echo "   - Link epics to visions: /pm:vision-match --epic <epic-name>"
fi

exit 0