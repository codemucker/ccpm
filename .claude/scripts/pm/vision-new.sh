#!/bin/bash

# PM Vision Creation System
# Creates new product vision or sub-vision with GitHub integration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
VISIONS_DIR="$PROJECT_ROOT/.claude/visions"

# Ensure visions directory exists
mkdir -p "$VISIONS_DIR"

show_help() {
    echo "📋 PM Vision Creation"
    echo ""
    echo "Usage:"
    echo "  /pm:vision-new <vision-name>           # Create product vision"
    echo "  /pm:vision-new <vision-name> --sub    # Create sub-vision"
    echo ""
    echo "Examples:"
    echo "  /pm:vision-new marketplace-platform"
    echo "  /pm:vision-new user-experience --sub"
}

if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

VISION_NAME="$1"
IS_SUB_VISION=false

if [[ "$2" == "--sub" ]]; then
    IS_SUB_VISION=true
fi

# Determine vision file location
# For product visions: put at project root as VISION.md (or VISION-{name}.md if multiple)
# For sub-visions: put in .claude/visions/ directory

if [[ "$IS_SUB_VISION" == "true" ]]; then
    # Sub-visions go in .claude/visions/
    VISION_FILE=$(echo "$VISION_NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')
    VISION_PATH="$VISIONS_DIR/$VISION_FILE.md"
else
    # Product visions go at project root
    if [[ -f "$PROJECT_ROOT/VISION.md" ]]; then
        # If VISION.md exists, create named variant
        VISION_FILE=$(echo "$VISION_NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')
        VISION_PATH="$PROJECT_ROOT/VISION-$VISION_FILE.md"
        VISION_FILE="VISION-$VISION_FILE"  # Update for tracking
    else
        # Use primary VISION.md
        VISION_PATH="$PROJECT_ROOT/VISION.md"
        VISION_FILE="VISION"
    fi
fi

if [[ -f "$VISION_PATH" ]]; then
    echo "❌ Vision '$VISION_NAME' already exists at: $VISION_PATH"
    exit 1
fi

# Check for existing vision files that need CCPM enhancement
EXISTING_VISION=""
for candidate in "$PROJECT_ROOT/VISION.md" "$PROJECT_ROOT/vision.md" "$PROJECT_ROOT/Vision.md"; do
    if [[ -f "$candidate" ]] && [[ "$candidate" != "$VISION_PATH" ]]; then
        EXISTING_VISION="$candidate"
        break
    fi
done

# Offer to enhance existing vision if found and we're not already using it
if [[ -n "$EXISTING_VISION" ]] && [[ ! "$IS_SUB_VISION" == "true" ]]; then
    echo "🔍 Found existing vision file: $(basename "$EXISTING_VISION")"
    echo ""
    read -p "🔄 Enhance this file with CCPM metadata? (y/n): " ENHANCE_VISION
    
    if [[ "$ENHANCE_VISION" =~ ^[Yy]$ ]]; then
        echo "📥 Enhancing existing vision..."
        
        # If we're creating VISION.md and it already exists, enhance in place
        if [[ "$VISION_PATH" == "$PROJECT_ROOT/VISION.md" ]]; then
            VISION_PATH="$EXISTING_VISION"
        else
            # Copy to our target location
            cp "$EXISTING_VISION" "$VISION_PATH"
        fi
        
        # Add CCPM metadata if not already present
        if ! grep -q "**Vision Type:**" "$VISION_PATH"; then
            # Create temp file with metadata header
            TEMP_FILE=$(mktemp)
            
            # Extract title if present
            TITLE=$(grep "^# " "$VISION_PATH" | head -1 | sed 's/^# //' || echo "$VISION_NAME")
            
            # Write enhanced header
            cat > "$TEMP_FILE" << EOF
# $TITLE

**Vision Type:** Product Vision
**Created:** $(date '+%Y-%m-%d')
**GitHub Issue:** _TBD_
**Enhanced from:** $(basename "$EXISTING_VISION")

EOF
            
            # Append original content (skip original title if it exists)
            if grep -q "^# " "$VISION_PATH"; then
                tail -n +2 "$VISION_PATH" >> "$TEMP_FILE"
            else
                cat "$VISION_PATH" >> "$TEMP_FILE"
            fi
            
            # Add CCPM footer if not present
            if ! grep -q "Claude Code PM" "$TEMP_FILE"; then
                cat >> "$TEMP_FILE" << EOF

---

*This vision was enhanced using Claude Code PM. Use \`/pm:vision-edit $VISION_FILE\` to modify.*
EOF
            fi
            
            # Replace original with enhanced version
            mv "$TEMP_FILE" "$VISION_PATH"
        fi
        
        echo "✅ Vision enhanced at: $VISION_PATH"
        
        # Skip template creation since we enhanced existing content
        SKIP_TEMPLATE=true
    fi
fi

# Check if this is a sub-vision and we need a parent
PARENT_VISION=""
if [[ "$IS_SUB_VISION" == "true" ]]; then
    echo "🔍 Available product visions:"
    if ls "$VISIONS_DIR"/*.md >/dev/null 2>&1; then
        for vision_file in "$VISIONS_DIR"/*.md; do
            if grep -q "Vision Type: Product Vision" "$vision_file" 2>/dev/null; then
                basename=$(basename "$vision_file" .md)
                title=$(grep "^# " "$vision_file" | head -1 | sed 's/^# //' || echo "$basename")
                echo "  - $basename: $title"
            fi
        done
    else
        echo "  No product visions found. Create a product vision first."
        exit 1
    fi
    
    echo ""
    read -p "Enter parent vision name: " PARENT_VISION
    
    PARENT_PATH="$VISIONS_DIR/$PARENT_VISION.md"
    if [[ ! -f "$PARENT_PATH" ]]; then
        echo "❌ Parent vision '$PARENT_VISION' not found"
        exit 1
    fi
fi

echo "🚀 Creating ${IS_SUB_VISION:+sub-}vision: $VISION_NAME"

# Create vision template (unless we imported existing content)
if [[ "$SKIP_TEMPLATE" != "true" ]]; then
cat > "$VISION_PATH" << EOF
# $VISION_NAME

**Vision Type:** $(if [[ "$IS_SUB_VISION" == "true" ]]; then echo "Sub-Vision"; else echo "Product Vision"; fi)
$(if [[ -n "$PARENT_VISION" ]]; then echo "**Parent Vision:** $PARENT_VISION"; fi)
**Created:** $(date '+%Y-%m-%d')
**GitHub Issue:** _TBD_

## Vision Statement

_Write a clear, compelling vision statement that describes what this $(if [[ "$IS_SUB_VISION" == "true" ]]; then echo "strategic theme"; else echo "product"; fi) will achieve._

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

$(if [[ "$IS_SUB_VISION" == "true" ]]; then echo "## Alignment with Parent Vision

_Explain how this sub-vision supports and advances the parent product vision._"; fi)

## Related Epics

_This section will be updated automatically as epics are linked to this vision._

## Status

**Current Phase:** Planning
**Progress:** 0% Complete
**Last Updated:** $(date '+%Y-%m-%d')

---

*This vision was created using Claude Code PM. Use \`/pm:vision-edit $VISION_FILE\` to modify.*
EOF

echo "✅ Vision created at: $VISION_PATH"
else
echo "✅ Vision ready at: $VISION_PATH"
fi

# Create symlink in .claude/visions/ for CCPM tracking (for product visions at root)
if [[ ! "$IS_SUB_VISION" == "true" ]] && [[ "$VISION_PATH" != "$VISIONS_DIR"* ]]; then
    SYMLINK_PATH="$VISIONS_DIR/$VISION_FILE.md"
    if [[ ! -f "$SYMLINK_PATH" ]]; then
        # Create relative symlink from .claude/visions/ to project root
        RELATIVE_PATH=$(realpath --relative-to="$VISIONS_DIR" "$VISION_PATH")
        ln -sf "$RELATIVE_PATH" "$SYMLINK_PATH"
        echo "🔗 Created tracking symlink at: .claude/visions/$(basename "$SYMLINK_PATH")"
    fi
fi

# Offer to create GitHub issue
echo ""
read -p "🔗 Create GitHub issue for this vision? (y/n): " CREATE_ISSUE

if [[ "$CREATE_ISSUE" =~ ^[Yy] ]]; then
    echo "🚀 Creating GitHub issue..."
    
    # Prepare issue body
    ISSUE_BODY=$(cat << 'EOI'
## Vision Overview

This is a $(if [[ "$IS_SUB_VISION" == "true" ]]; then echo "sub-vision (strategic theme)"; else echo "product vision"; fi) that provides strategic direction for development efforts.

**📁 Local File:** `.claude/visions/VISION_FILE.md`

## Purpose

This issue tracks the overall progress and discussion for this vision. Individual epics will reference this issue to maintain strategic alignment.

## Related Work

- [ ] Epic tracking and progress updates will appear here
- [ ] Cross-references will be maintained automatically by ccpm

---

🤖 *This issue was created by Claude Code PM vision system*
EOI
)
    
    # Replace placeholders
    ISSUE_BODY=${ISSUE_BODY//VISION_FILE/$VISION_FILE}
    ISSUE_BODY=${ISSUE_BODY//\$IS_SUB_VISION/$IS_SUB_VISION}
    
    # Create the issue
    VISION_TITLE="Vision: $VISION_NAME"
    if [[ "$IS_SUB_VISION" == "true" ]]; then
        VISION_TITLE="Sub-Vision: $VISION_NAME"
    fi
    
    if command -v gh >/dev/null 2>&1; then
        ISSUE_NUMBER=$(gh issue create \
            --title "$VISION_TITLE" \
            --body "$ISSUE_BODY" \
            --label "vision$(if [[ "$IS_SUB_VISION" == "true" ]]; then echo ",sub-vision"; fi)" \
            | grep -o '#[0-9]*' | tr -d '#')
        
        if [[ -n "$ISSUE_NUMBER" ]]; then
            echo "✅ GitHub issue #$ISSUE_NUMBER created"
            
            # Update the vision file with GitHub issue number
            sed -i "s/**GitHub Issue:** _TBD_/**GitHub Issue:** #$ISSUE_NUMBER/" "$VISION_PATH"
            
            echo "🔗 Vision linked to GitHub issue #$ISSUE_NUMBER"
        fi
    else
        echo "⚠️  GitHub CLI not available. Install 'gh' to create issues automatically."
        echo "📋 Manual issue creation template saved to: $VISION_PATH.github-template"
        
        echo "$ISSUE_BODY" > "$VISION_PATH.github-template"
    fi
fi

echo ""
echo "🎯 Next steps:"
echo "   1. Edit vision details: /pm:vision-edit $VISION_FILE"
if [[ "$IS_SUB_VISION" == "false" ]]; then
    echo "   2. Create sub-visions: /pm:vision-new <name> --sub"
fi
echo "   3. Create PRDs referencing this vision: /pm:prd-new <name> --vision $VISION_FILE"
echo "   4. View all visions: /pm:vision-list"

exit 0