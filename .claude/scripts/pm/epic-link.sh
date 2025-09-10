#!/bin/bash

# PM Epic-Vision Linking System
# Links epics to visions with validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
VISIONS_DIR="$PROJECT_ROOT/.claude/visions"
EPICS_DIR="$PROJECT_ROOT/.claude/epics"

show_help() {
    echo "🔗 PM Epic-Vision Linking"
    echo ""
    echo "Usage:"
    echo "  /pm:epic-link <epic-name> <vision-name>    # Link epic to vision"
    echo "  /pm:epic-link --unlink <epic-name>         # Remove vision link"
    echo "  /pm:epic-link --show <epic-name>           # Show current links"
    echo ""
    echo "Examples:"
    echo "  /pm:epic-link user-onboarding user-experience"
    echo "  /pm:epic-link --unlink user-onboarding"
    echo "  /pm:epic-link --show user-onboarding"
}

if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

ACTION="link"
EPIC_NAME=""
VISION_NAME=""

# Parse arguments
if [[ "$1" == "--unlink" ]]; then
    ACTION="unlink"
    EPIC_NAME="$2"
elif [[ "$1" == "--show" ]]; then
    ACTION="show"
    EPIC_NAME="$2"
else
    EPIC_NAME="$1"
    VISION_NAME="$2"
fi

if [[ -z "$EPIC_NAME" ]]; then
    echo "❌ Epic name required"
    show_help
    exit 1
fi

# Validate epic exists
EPIC_FILE="$EPICS_DIR/$EPIC_NAME/epic.md"
if [[ ! -f "$EPIC_FILE" ]]; then
    echo "❌ Epic not found: $EPIC_NAME"
    echo "   Expected: $EPIC_FILE"
    exit 1
fi

case "$ACTION" in
    "show")
        echo "🔍 Vision Links for Epic: $EPIC_NAME"
        echo ""
        
        # Get current vision information
        vision_support=$(grep "^vision-support:" "$EPIC_FILE" 2>/dev/null | sed 's/^vision-support: *//' | sed 's/\[.*\]//' | tr -d '"' | xargs)
        github_vision_link=$(grep "^github-vision-link:" "$EPIC_FILE" 2>/dev/null | sed 's/^github-vision-link: *//' | sed 's/\[.*\]//' | tr -d '"' | xargs)
        body_vision_support=$(grep -A 1 "Vision-Support:" "$EPIC_FILE" 2>/dev/null | tail -1 | sed 's/^.*"//' | sed 's/".*$//' | xargs)
        
        # Use body vision if frontmatter is placeholder
        if [[ -z "$vision_support" ]] || [[ "$vision_support" =~ ^\[.*\]$ ]]; then
            vision_support="$body_vision_support"
        fi
        
        echo "📋 Current Status:"
        if [[ -n "$vision_support" ]] && [[ "$vision_support" != "_TBD_" ]] && [[ ! "$vision_support" =~ ^\[.*\]$ ]]; then
            echo "   ✅ Vision Description: $vision_support"
        else
            echo "   ❌ No vision description"
        fi
        
        if [[ -n "$github_vision_link" ]] && [[ "$github_vision_link" != "_TBD_" ]] && [[ ! "$github_vision_link" =~ ^\[.*\]$ ]]; then
            echo "   🔗 GitHub Link: $github_vision_link"
            
            # Validate GitHub link
            if command -v gh >/dev/null 2>&1 && [[ "$github_vision_link" =~ ^#[0-9]+$ ]]; then
                issue_num=${github_vision_link#\#}
                if gh issue view "$issue_num" >/dev/null 2>&1; then
                    issue_title=$(gh issue view "$issue_num" --json title -q '.title' 2>/dev/null || echo "")
                    echo "   ✅ Link Valid: $issue_title"
                else
                    echo "   ❌ Link Broken: Issue not found"
                fi
            fi
        else
            echo "   ⚠️  No GitHub link"
        fi
        
        echo ""
        echo "🔧 Actions:"
        echo "   /pm:vision-match --epic $EPIC_NAME      # Find matching vision"
        echo "   /pm:epic-link $EPIC_NAME <vision-name>  # Link to specific vision"
        echo "   /pm:epic-link --unlink $EPIC_NAME       # Remove links"
        ;;
        
    "unlink")
        echo "🔗 Unlinking Epic from Vision: $EPIC_NAME"
        
        # Remove vision links
        sed -i 's/^vision-support: .*/vision-support: [Describe how this epic supports the product vision]/' "$EPIC_FILE"
        sed -i 's/^github-vision-link: .*/github-vision-link: [Will be auto-populated by vision matching]/' "$EPIC_FILE"
        
        # Update body section
        if grep -q "Vision-Support:" "$EPIC_FILE"; then
            sed -i '/Vision-Support:/,/^$/ {
                s/Vision-Support: .*/Vision-Support: "[Describe how this epic advances the product vision or strategic theme]"/
                /GitHub-Vision-Link:/ s/GitHub-Vision-Link: .*/GitHub-Vision-Link: _TBD_ (will be populated by `\/pm:vision-match --epic '"$EPIC_NAME"'`)/
            }' "$EPIC_FILE"
        fi
        
        echo "✅ Vision links removed from epic"
        echo ""
        echo "🔧 To re-link:"
        echo "   /pm:vision-match --epic $EPIC_NAME"
        ;;
        
    "link")
        if [[ -z "$VISION_NAME" ]]; then
            echo "❌ Vision name required for linking"
            show_help
            exit 1
        fi
        
        # Validate vision exists
        VISION_FILE="$VISIONS_DIR/$VISION_NAME.md"
        if [[ ! -f "$VISION_FILE" ]]; then
            echo "❌ Vision not found: $VISION_NAME"
            echo "   Expected: $VISION_FILE"
            echo ""
            echo "📋 Available visions:"
            if [[ -d "$VISIONS_DIR" ]]; then
                for vision_file in "$VISIONS_DIR"/*.md; do
                    if [[ -f "$vision_file" ]]; then
                        vision=$(basename "$vision_file" .md)
                        title=$(grep "^# " "$vision_file" | head -1 | sed 's/^# //' 2>/dev/null || echo "$vision")
                        echo "   • $vision: $title"
                    fi
                done
            fi
            exit 1
        fi
        
        # Get vision information
        vision_title=$(grep "^# " "$VISION_FILE" | head -1 | sed 's/^# //' 2>/dev/null || echo "$VISION_NAME")
        vision_github=$(grep "GitHub Issue:" "$VISION_FILE" | sed 's/.*GitHub Issue: *//' | sed 's/\*\*//' 2>/dev/null || echo "")
        vision_type=$(grep "Vision Type:" "$VISION_FILE" | sed 's/.*Vision Type: *//' | sed 's/\*\*//' 2>/dev/null || echo "Unknown")
        
        echo "🔗 Linking Epic to Vision"
        echo ""
        echo "   Epic: $EPIC_NAME"
        echo "   Vision: $vision_title ($vision_type)"
        if [[ -n "$vision_github" ]] && [[ "$vision_github" != "_TBD_" ]]; then
            echo "   GitHub: $vision_github"
        fi
        
        # Prompt for vision support description
        echo ""
        echo "📝 Please describe how this epic supports the vision:"
        echo "   Vision: $vision_title"
        echo ""
        read -p "   Description: " VISION_DESCRIPTION
        
        if [[ -z "$VISION_DESCRIPTION" ]]; then
            echo "❌ Description required for linking"
            exit 1
        fi
        
        echo ""
        echo "🔧 Updating epic with vision information..."
        
        # Update frontmatter
        sed -i "s/^vision-support: .*/vision-support: \"$VISION_DESCRIPTION\"/" "$EPIC_FILE"
        
        if [[ -n "$vision_github" ]] && [[ "$vision_github" != "_TBD_" ]]; then
            sed -i "s/^github-vision-link: .*/github-vision-link: $vision_github/" "$EPIC_FILE"
        fi
        
        # Update body section
        if grep -q "Vision-Support:" "$EPIC_FILE"; then
            sed -i "s/Vision-Support: .*/Vision-Support: \"$VISION_DESCRIPTION\"/" "$EPIC_FILE"
            
            if [[ -n "$vision_github" ]] && [[ "$vision_github" != "_TBD_" ]]; then
                sed -i "/GitHub-Vision-Link:/ s/GitHub-Vision-Link: .*/GitHub-Vision-Link: $vision_github/" "$EPIC_FILE"
            fi
        fi
        
        echo "✅ Epic successfully linked to vision"
        echo ""
        echo "📋 Summary:"
        echo "   Epic: $EPIC_NAME"
        echo "   Vision: $vision_title"
        echo "   Description: $VISION_DESCRIPTION"
        if [[ -n "$vision_github" ]] && [[ "$vision_github" != "_TBD_" ]]; then
            echo "   GitHub Link: $vision_github"
        fi
        
        echo ""
        echo "🔧 Next steps:"
        echo "   /pm:epic-show $EPIC_NAME           # View updated epic"
        echo "   /pm:vision-audit $EPIC_NAME        # Validate links"
        echo "   /pm:epic-decompose $EPIC_NAME      # Break into tasks"
        ;;
esac

exit 0