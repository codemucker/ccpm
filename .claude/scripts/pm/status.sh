#!/bin/bash

echo "Getting status..."
echo ""
echo ""


echo "📊 Project Status"
echo "================"
echo ""

echo "🎯 Visions:"
if [ -d ".claude/visions" ]; then
  product_visions=$(find .claude/visions -name "*.md" -exec grep -l "Vision Type: Product Vision" {} \; 2>/dev/null | wc -l)
  sub_visions=$(find .claude/visions -name "*.md" -exec grep -l "Vision Type: Sub-Vision" {} \; 2>/dev/null | wc -l)
  total_visions=$((product_visions + sub_visions))
  echo "  Product Visions: $product_visions"
  echo "  Sub-Visions: $sub_visions"
  echo "  Total: $total_visions"
else
  echo "  No visions found - create one with /pm:vision-new"
fi

echo ""
echo "📄 PRDs:"
if [ -d ".claude/prds" ]; then
  total=$(ls .claude/prds/*.md 2>/dev/null | wc -l)
  echo "  Total: $total"
else
  echo "  No PRDs found"
fi

echo ""
echo "📚 Epics:"
if [ -d ".claude/epics" ]; then
  total=$(ls -d .claude/epics/*/ 2>/dev/null | wc -l)
  echo "  Total: $total"
  
  # Count vision-linked epics
  linked=0
  orphaned=0
  
  for epic_dir in .claude/epics/*/; do
    if [ -d "$epic_dir" ]; then
      epic_file="$epic_dir/epic.md"
      if [ -f "$epic_file" ]; then
        # Check for vision support in frontmatter or body
        vision_support=$(grep "^vision-support:" "$epic_file" 2>/dev/null | sed 's/^vision-support: *//' | sed 's/\[.*\]//' | tr -d '"' | xargs)
        body_vision_support=$(grep -A 1 "Vision-Support:" "$epic_file" 2>/dev/null | tail -1 | sed 's/^.*"//' | sed 's/".*$//' | xargs)
        
        if [ -z "$vision_support" ] || [[ "$vision_support" =~ ^\[.*\]$ ]]; then
          vision_support="$body_vision_support"
        fi
        
        if [ -n "$vision_support" ] && [ "$vision_support" != "_TBD_" ] && [[ ! "$vision_support" =~ ^\[.*\]$ ]]; then
          linked=$((linked + 1))
        else
          orphaned=$((orphaned + 1))
        fi
      fi
    fi
  done
  
  echo "  Vision-Linked: $linked"
  echo "  Orphaned: $orphaned"
else
  echo "  No epics found"
fi

echo ""
echo "📝 Tasks:"
if [ -d ".claude/epics" ]; then
  total=$(find .claude/epics -name "[0-9]*.md" 2>/dev/null | wc -l)
  open=$(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *open" {} \; 2>/dev/null | wc -l)
  closed=$(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *closed" {} \; 2>/dev/null | wc -l)
  echo "  Open: $open"
  echo "  Closed: $closed"
  echo "  Total: $total"
else
  echo "  No tasks found"
fi

exit 0
