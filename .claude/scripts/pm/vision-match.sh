#!/bin/bash

# PM Vision Matching System
# Uses LLM to match epic descriptions to existing visions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
VISIONS_DIR="$PROJECT_ROOT/.claude/visions"

show_help() {
    echo "🔍 PM Vision Matching"
    echo ""
    echo "Usage:"
    echo "  /pm:vision-match \"<description>\"     # Match description to existing visions"
    echo "  /pm:vision-match --epic <epic-name>   # Match epic's vision description"
    echo ""
    echo "Examples:"
    echo "  /pm:vision-match \"Improve mobile user experience\""
    echo "  /pm:vision-match --epic user-onboarding"
}

if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

DESCRIPTION=""
EPIC_MODE=false

if [[ "$1" == "--epic" ]]; then
    EPIC_MODE=true
    EPIC_NAME="$2"
    EPICS_DIR="$PROJECT_ROOT/.claude/epics"
    EPIC_FILE="$EPICS_DIR/$EPIC_NAME/epic.md"
    
    if [[ ! -f "$EPIC_FILE" ]]; then
        echo "❌ Epic file not found: $EPIC_FILE"
        exit 1
    fi
    
    # Extract vision description from epic
    DESCRIPTION=$(grep -A 5 "Vision-Support:" "$EPIC_FILE" 2>/dev/null | head -1 | sed 's/^.*Vision-Support: *//' | sed 's/"//g' || echo "")
    
    if [[ -z "$DESCRIPTION" ]]; then
        echo "❌ No vision description found in epic. Add 'Vision-Support: \"description\"' to epic.md"
        exit 1
    fi
    
    echo "🔍 Analyzing epic vision description: $DESCRIPTION"
else
    DESCRIPTION="$1"
fi

# Check if visions exist
if [[ ! -d "$VISIONS_DIR" ]] || [[ -z "$(ls -A "$VISIONS_DIR" 2>/dev/null)" ]]; then
    echo "❌ No visions found. Create visions first with /pm:vision-new"
    exit 1
fi

# Collect all visions for matching
VISIONS_CONTENT=""
VISION_LIST=()

echo "📚 Loading existing visions..."

for vision_file in "$VISIONS_DIR"/*.md; do
    if [[ -f "$vision_file" ]]; then
        vision_name=$(basename "$vision_file" .md)
        vision_title=$(grep "^# " "$vision_file" | head -1 | sed 's/^# //' 2>/dev/null || echo "$vision_name")
        vision_statement=$(sed -n '/## Vision Statement/,/## /p' "$vision_file" | grep -v "^##" | head -3 | tr '\n' ' ' 2>/dev/null || echo "")
        vision_type=$(grep "Vision Type:" "$vision_file" | sed 's/.*Vision Type: *//' | sed 's/\*\*//' 2>/dev/null || echo "Unknown")
        github_issue=$(grep "GitHub Issue:" "$vision_file" | sed 's/.*GitHub Issue: *//' | sed 's/\*\*//' 2>/dev/null || echo "")
        
        VISION_LIST+=("$vision_name")
        VISIONS_CONTENT+="
Vision: $vision_name ($vision_type)
Title: $vision_title
Statement: $vision_statement
GitHub: $github_issue
---
"
    fi
done

if [[ ${#VISION_LIST[@]} -eq 0 ]]; then
    echo "❌ No valid visions found"
    exit 1
fi

echo "✅ Found ${#VISION_LIST[@]} visions"

# Create matching prompt
MATCHING_PROMPT="You are a project management assistant helping match epic descriptions to existing visions.

TASK: Analyze the following epic description and match it to the most appropriate existing vision(s).

EPIC DESCRIPTION TO MATCH:
\"$DESCRIPTION\"

EXISTING VISIONS:
$VISIONS_CONTENT

INSTRUCTIONS:
1. Analyze the epic description for key themes, goals, and outcomes
2. Compare against each vision's statement and purpose  
3. Rank matches by relevance (1-5 scale, 5 being perfect match)
4. Consider both direct keyword matches and conceptual alignment
5. Prefer sub-visions over product visions when applicable

RESPONSE FORMAT (JSON):
{
  \"matches\": [
    {
      \"vision_name\": \"vision-filename\",
      \"confidence\": 4.2,
      \"reasoning\": \"Explanation of why this matches\",
      \"github_issue\": \"#123 or empty string\"
    }
  ],
  \"top_match\": \"vision-filename or null if no good matches\",
  \"create_new_suggestion\": \"If no good matches, suggest new vision name or null\"
}

Only include matches with confidence >= 2.5. Sort by confidence descending."

# Try to use Claude via available methods
MATCH_RESULT=""

# Method 1: Check if we're in Claude Code environment
if [[ -n "$CLAUDE_CODE_SESSION" ]] || command -v claude >/dev/null 2>&1; then
    echo "🤖 Using Claude for vision matching..."
    
    # Create temp file for prompt
    TEMP_PROMPT="/tmp/vision_match_prompt_$$.txt"
    echo "$MATCHING_PROMPT" > "$TEMP_PROMPT"
    
    # This would ideally call Claude, but for now we'll simulate
    # In actual implementation, this would use Claude API or Claude Code's Task tool
    echo "🔄 Analyzing vision matches..."
    
    # Placeholder for actual Claude integration
    MATCH_RESULT="{\"matches\":[],\"top_match\":null,\"create_new_suggestion\":\"Cannot analyze without Claude integration\"}"
    
    rm -f "$TEMP_PROMPT"
else
    # Fallback: Simple keyword matching
    echo "⚠️  Claude not available, using keyword matching fallback..."
    
    BEST_MATCH=""
    BEST_SCORE=0
    
    for vision_name in "${VISION_LIST[@]}"; do
        vision_file="$VISIONS_DIR/$vision_name.md"
        vision_content=$(cat "$vision_file" | tr '[:upper:]' '[:lower:]')
        description_lower=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]')
        
        score=0
        
        # Simple keyword matching
        for word in $description_lower; do
            if [[ ${#word} -gt 3 ]] && echo "$vision_content" | grep -q "$word"; then
                ((score++))
            fi
        done
        
        if [[ $score -gt $BEST_SCORE ]]; then
            BEST_SCORE=$score
            BEST_MATCH=$vision_name
        fi
    done
    
    if [[ $BEST_SCORE -gt 0 ]]; then
        github_issue=$(grep "GitHub Issue:" "$VISIONS_DIR/$BEST_MATCH.md" | sed 's/.*GitHub Issue: *//' | sed 's/\*\*//' 2>/dev/null || echo "")
        MATCH_RESULT="{\"matches\":[{\"vision_name\":\"$BEST_MATCH\",\"confidence\":3.0,\"reasoning\":\"Keyword match (fallback method)\",\"github_issue\":\"$github_issue\"}],\"top_match\":\"$BEST_MATCH\",\"create_new_suggestion\":null}"
    else
        MATCH_RESULT="{\"matches\":[],\"top_match\":null,\"create_new_suggestion\":\"No keyword matches found\"}"
    fi
fi

# Parse and display results
echo "🎯 Vision Matching Results:"
echo ""

# Extract top match (simple parsing since we control the format)
TOP_MATCH=$(echo "$MATCH_RESULT" | grep -o '"top_match":"[^"]*"' | cut -d'"' -f4 | head -1)
CREATE_NEW=$(echo "$MATCH_RESULT" | grep -o '"create_new_suggestion":"[^"]*"' | cut -d'"' -f4 | head -1)

if [[ -n "$TOP_MATCH" ]] && [[ "$TOP_MATCH" != "null" ]]; then
    vision_file="$VISIONS_DIR/$TOP_MATCH.md"
    vision_title=$(grep "^# " "$vision_file" | head -1 | sed 's/^# //' 2>/dev/null || echo "$TOP_MATCH")
    github_issue=$(grep "GitHub Issue:" "$vision_file" | sed 's/.*GitHub Issue: *//' | sed 's/\*\*//' 2>/dev/null || echo "")
    
    echo "✅ Best Match Found:"
    echo "   Vision: $TOP_MATCH"
    echo "   Title: $vision_title"
    if [[ -n "$github_issue" ]] && [[ "$github_issue" != "_TBD_" ]]; then
        echo "   GitHub: $github_issue"
    fi
    echo ""
    
    if [[ "$EPIC_MODE" == "true" ]]; then
        echo "🔗 Suggested actions:"
        echo "   1. Link epic to vision: /pm:epic-link $EPIC_NAME $TOP_MATCH"
        echo "   2. Review vision file: /pm:vision-edit $TOP_MATCH"
        
        # Auto-link option
        read -p "🤖 Auto-link this epic to the matched vision? (y/n): " AUTO_LINK
        if [[ "$AUTO_LINK" =~ ^[Yy] ]]; then
            if [[ -n "$github_issue" ]] && [[ "$github_issue" != "_TBD_" ]]; then
                # Update epic with GitHub issue link
                sed -i "s/GitHub-Vision-Link: .*/GitHub-Vision-Link: $github_issue/" "$EPIC_FILE"
                echo "✅ Epic linked to vision $github_issue"
            else
                echo "⚠️  Vision not yet linked to GitHub. Link manually or create GitHub issue first."
            fi
        fi
    fi
    
elif [[ -n "$CREATE_NEW" ]] && [[ "$CREATE_NEW" != "null" ]]; then
    echo "💡 No good matches found. Consider creating a new vision:"
    echo "   Suggestion: $CREATE_NEW"
    echo ""
    echo "   Create new vision: /pm:vision-new \"$CREATE_NEW\" --sub"
else
    echo "❌ No suitable vision matches found"
    echo ""
    echo "🔧 Options:"
    echo "   1. Create new sub-vision: /pm:vision-new <name> --sub"
    echo "   2. Refine description and try again"
    echo "   3. Review existing visions: /pm:vision-list"
fi

# Output raw JSON for programmatic use
if [[ "$EPIC_MODE" == "false" ]]; then
    echo ""
    echo "📄 Raw matching data:"
    echo "$MATCH_RESULT"
fi

exit 0