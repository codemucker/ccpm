#!/bin/bash

# PM Vision List System
# Lists all visions with status and relationships

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
VISIONS_DIR="$PROJECT_ROOT/.claude/visions"
EPICS_DIR="$PROJECT_ROOT/.claude/epics"

show_help() {
    echo "📋 PM Vision List"
    echo ""
    echo "Usage:"
    echo "  /pm:vision-list              # List all visions"
    echo "  /pm:vision-list --tree       # Show vision hierarchy"
    echo "  /pm:vision-list --status     # Include progress status"
    echo ""
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

MODE="simple"
if [[ "$1" == "--tree" ]]; then
    MODE="tree"
elif [[ "$1" == "--status" ]]; then
    MODE="status"
fi

echo "📋 Project Visions"
echo "=================="

# Check if visions exist
if [[ ! -d "$VISIONS_DIR" ]] || [[ -z "$(ls -A "$VISIONS_DIR" 2>/dev/null)" ]]; then
    echo ""
    echo "❌ No visions found."
    echo ""
    echo "💡 Create your first vision:"
    echo "   /pm:vision-new <vision-name>      # Product vision"
    echo "   /pm:vision-new <name> --sub       # Sub-vision"
    exit 0
fi

# Collect vision information
declare -A product_visions
declare -A sub_visions
declare -A vision_titles
declare -A vision_github
declare -A vision_progress

for vision_file in "$VISIONS_DIR"/*.md; do
    if [[ -f "$vision_file" ]]; then
        vision_name=$(basename "$vision_file" .md)
        vision_title=$(grep "^# " "$vision_file" | head -1 | sed 's/^# //' 2>/dev/null || echo "$vision_name")
        vision_type=$(grep "Vision Type:" "$vision_file" | sed 's/.*Vision Type: *//' | sed 's/\*\*//' 2>/dev/null || echo "Unknown")
        parent_vision=$(grep "Parent Vision:" "$vision_file" | sed 's/.*Parent Vision: *//' | sed 's/\*\*//' 2>/dev/null || echo "")
        github_issue=$(grep "GitHub Issue:" "$vision_file" | sed 's/.*GitHub Issue: *//' | sed 's/\*\*//' 2>/dev/null || echo "")
        
        vision_titles[$vision_name]="$vision_title"
        vision_github[$vision_name]="$github_issue"
        
        if [[ "$vision_type" == "Product Vision" ]]; then
            product_visions[$vision_name]=1
        elif [[ "$vision_type" == "Sub-Vision" ]] && [[ -n "$parent_vision" ]]; then
            if [[ -z "${sub_visions[$parent_vision]}" ]]; then
                sub_visions[$parent_vision]="$vision_name"
            else
                sub_visions[$parent_vision]="${sub_visions[$parent_vision]} $vision_name"
            fi
        fi
        
        # Calculate progress if requested
        if [[ "$MODE" == "status" ]]; then
            linked_epics=0
            total_epics=0
            
            if [[ -d "$EPICS_DIR" ]]; then
                for epic_dir in "$EPICS_DIR"/*/; do
                    if [[ -d "$epic_dir" ]]; then
                        epic_file="$epic_dir/epic.md"
                        if [[ -f "$epic_file" ]]; then
                            epic_github_link=$(grep "^github-vision-link:" "$epic_file" 2>/dev/null | sed 's/^github-vision-link: *//' | tr -d '"' | xargs)
                            if [[ "$epic_github_link" == "$github_issue" ]]; then
                                ((total_epics++))
                                epic_status=$(grep "^status:" "$epic_file" 2>/dev/null | sed 's/^status: *//' | tr -d '"' | xargs)
                                if [[ "$epic_status" == "completed" ]] || [[ "$epic_status" == "done" ]]; then
                                    ((linked_epics++))
                                fi
                            fi
                        fi
                    fi
                done
            fi
            
            if [[ $total_epics -gt 0 ]]; then
                progress=$((linked_epics * 100 / total_epics))
                vision_progress[$vision_name]="${linked_epics}/${total_epics} (${progress}%)"
            else
                vision_progress[$vision_name]="0/0 (0%)"
            fi
        fi
    fi
done

# Display visions based on mode
case "$MODE" in
    "tree")
        echo ""
        for product_vision in "${!product_visions[@]}"; do
            title="${vision_titles[$product_vision]}"
            github="${vision_github[$product_vision]}"
            
            echo "🎯 $title"
            echo "   Vision: $product_vision"
            if [[ -n "$github" ]] && [[ "$github" != "_TBD_" ]]; then
                echo "   GitHub: $github"
            fi
            
            # Show sub-visions
            if [[ -n "${sub_visions[$product_vision]}" ]]; then
                echo "   Sub-Visions:"
                for sub_vision in ${sub_visions[$product_vision]}; do
                    sub_title="${vision_titles[$sub_vision]}"
                    sub_github="${vision_github[$sub_vision]}"
                    
                    echo "   ├─ 🎭 $sub_title"
                    echo "   │  Vision: $sub_vision"
                    if [[ -n "$sub_github" ]] && [[ "$sub_github" != "_TBD_" ]]; then
                        echo "   │  GitHub: $sub_github"
                    fi
                done
            fi
            echo ""
        done
        
        # Show orphaned sub-visions (parent not found)
        orphaned_subs=()
        for vision_file in "$VISIONS_DIR"/*.md; do
            if [[ -f "$vision_file" ]]; then
                vision_name=$(basename "$vision_file" .md)
                vision_type=$(grep "Vision Type:" "$vision_file" | sed 's/.*Vision Type: *//' | sed 's/\*\*//' 2>/dev/null || echo "Unknown")
                parent_vision=$(grep "Parent Vision:" "$vision_file" | sed 's/.*Parent Vision: *//' | sed 's/\*\*//' 2>/dev/null || echo "")
                
                if [[ "$vision_type" == "Sub-Vision" ]] && [[ -n "$parent_vision" ]]; then
                    if [[ -z "${product_visions[$parent_vision]}" ]]; then
                        orphaned_subs+=("$vision_name (parent: $parent_vision)")
                    fi
                fi
            fi
        done
        
        if [[ ${#orphaned_subs[@]} -gt 0 ]]; then
            echo "⚠️  Orphaned Sub-Visions:"
            for orphan in "${orphaned_subs[@]}"; do
                echo "   ❌ $orphan"
            done
            echo ""
        fi
        ;;
        
    "status")
        echo ""
        echo "📊 Vision Status Report:"
        echo ""
        
        for product_vision in "${!product_visions[@]}"; do
            title="${vision_titles[$product_vision]}"
            github="${vision_github[$product_vision]}"
            progress="${vision_progress[$product_vision]}"
            
            echo "🎯 $title"
            echo "   Vision: $product_vision"
            if [[ -n "$github" ]] && [[ "$github" != "_TBD_" ]]; then
                echo "   GitHub: $github"
            fi
            echo "   Progress: $progress"
            
            # Show sub-vision status
            if [[ -n "${sub_visions[$product_vision]}" ]]; then
                echo "   Sub-Visions:"
                for sub_vision in ${sub_visions[$product_vision]}; do
                    sub_title="${vision_titles[$sub_vision]}"
                    sub_progress="${vision_progress[$sub_vision]}"
                    
                    echo "   ├─ 🎭 $sub_title ($sub_progress)"
                done
            fi
            echo ""
        done
        ;;
        
    *)
        echo ""
        
        # Product visions
        if [[ ${#product_visions[@]} -gt 0 ]]; then
            echo "🎯 Product Visions:"
            for product_vision in "${!product_visions[@]}"; do
                title="${vision_titles[$product_vision]}"
                github="${vision_github[$product_vision]}"
                
                echo "   • $title"
                echo "     File: $product_vision.md"
                if [[ -n "$github" ]] && [[ "$github" != "_TBD_" ]]; then
                    echo "     GitHub: $github"
                fi
            done
            echo ""
        fi
        
        # Sub-visions
        total_subs=0
        for parent in "${!sub_visions[@]}"; do
            for sub in ${sub_visions[$parent]}; do
                ((total_subs++))
            done
        done
        
        if [[ $total_subs -gt 0 ]]; then
            echo "🎭 Sub-Visions:"
            for parent in "${!product_visions[@]}"; do
                if [[ -n "${sub_visions[$parent]}" ]]; then
                    parent_title="${vision_titles[$parent]}"
                    echo "   Under '$parent_title':"
                    for sub_vision in ${sub_visions[$parent]}; do
                        sub_title="${vision_titles[$sub_vision]}"
                        sub_github="${vision_github[$sub_vision]}"
                        
                        echo "     • $sub_title"
                        echo "       File: $sub_vision.md"
                        if [[ -n "$sub_github" ]] && [[ "$sub_github" != "_TBD_" ]]; then
                            echo "       GitHub: $sub_github"
                        fi
                    done
                    echo ""
                fi
            done
        fi
        ;;
esac

# Show summary
echo "📈 Summary:"
echo "   Product Visions: ${#product_visions[@]}"

total_subs=0
for parent in "${!sub_visions[@]}"; do
    for sub in ${sub_visions[$parent]}; do
        ((total_subs++))
    done
done
echo "   Sub-Visions: $total_subs"

echo ""
echo "🔧 Available Actions:"
echo "   /pm:vision-new <name>          # Create product vision"
echo "   /pm:vision-new <name> --sub    # Create sub-vision"
echo "   /pm:vision-audit               # Audit vision-epic links"
echo "   /pm:vision-edit <name>         # Edit vision file"

exit 0