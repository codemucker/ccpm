#!/bin/bash

# PM Anti-Cheat System  
# Detect hardcoded responses, cheat patterns, simulation code, and other non-genuine implementations

echo "🕵️ Cheat Detection Starting..."
echo "=================================="

# Get parameters
target_path="${1:-.}"
language_filter="$2"
strict_mode="$3"
report_file="$4"

if [[ ! -d "$target_path" ]]; then
    echo "❌ Path not found: $target_path"
    exit 1
fi

echo "📁 Scanning: $target_path"
echo "🎯 Language: ${language_filter:-"auto-detect"}"
echo "⚡ Strict mode: ${strict_mode:-"disabled"}"

# Find production files (exclude tests, docs, configs)
production_files=()

case "$language_filter" in
    "typescript"|"ts")
        mapfile -t production_files < <(find "$target_path" -name "*.ts" -not -path "*/test*" -not -name "*.test.*" -not -name "*.spec.*" -not -path "*/node_modules/*" -not -path "*/.git/*")
        ;;
    "kotlin"|"kt")
        mapfile -t production_files < <(find "$target_path" -name "*.kt" -not -path "*/test*" -not -name "*Test.kt" -not -path "*/build/*" -not -path "*/.git/*")
        ;;
    "python"|"py")
        mapfile -t production_files < <(find "$target_path" -name "*.py" -not -path "*/test*" -not -name "*test*.py" -not -name "test_*.py" -not -path "*/__pycache__/*" -not -path "*/.git/*")
        ;;
    "java")
        mapfile -t production_files < <(find "$target_path" -name "*.java" -not -path "*/test*" -not -name "*Test.java" -not -path "*/target/*" -not -path "*/.git/*")
        ;;
    *)
        # Auto-detect common production files
        mapfile -t production_files < <(find "$target_path" \( -name "*.ts" -o -name "*.js" -o -name "*.kt" -o -name "*.py" -o -name "*.java" -o -name "*.rs" -o -name "*.go" \) -not -path "*/test*" -not -name "*test*" -not -name "*Test*" -not -path "*/node_modules/*" -not -path "*/build/*" -not -path "*/target/*" -not -path "*/__pycache__/*" -not -path "*/.git/*")
        ;;
esac

echo "📊 Found ${#production_files[@]} production files to scan"

if [[ ${#production_files[@]} -eq 0 ]]; then
    echo "❌ No production files found to scan"
    exit 1
fi

# Hardcoded Response Detection
echo ""
echo "🎭 HARDCODED RESPONSE DETECTION"
echo "==============================="

hardcoded_issues=()

for file in "${production_files[@]}"; do
    echo ""
    echo "🔍 Scanning: $file"
    
    if [[ ! -f "$file" ]]; then
        continue
    fi
    
    file_issues=()
    
    # Hardcoded JSON responses
    hardcoded_json=$(grep -n "return.*{.*:" "$file" | grep -v "return.*new\|return.*Object\|return.*{.*[a-zA-Z]*(" || echo "")
    if [[ -n "$hardcoded_json" ]]; then
        file_issues+=("HARDCODED-JSON: Hardcoded object/JSON returns detected:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$hardcoded_json"
    fi
    
    # Hardcoded array responses
    hardcoded_arrays=$(grep -n "return \[.*\]" "$file" | grep -v "return.*new\|return.*Array\|return.*\.map\|return.*\.filter" || echo "")
    if [[ -n "$hardcoded_arrays" ]]; then
        file_issues+=("HARDCODED-ARRAY: Hardcoded array returns detected:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$hardcoded_arrays"
    fi
    
    # Hardcoded string responses (suspicious patterns)
    hardcoded_strings=$(grep -n 'return ".*"' "$file" | grep -E '"(success|error|true|false|ok|fail|yes|no|hello|welcome)"' || echo "")
    if [[ -n "$hardcoded_strings" ]]; then
        file_issues+=("HARDCODED-STRING: Suspicious hardcoded string returns:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$hardcoded_strings"
    fi
    
    # Hardcoded numeric responses (magic numbers)
    hardcoded_numbers=$(grep -n "return [0-9]\+\|return -[0-9]\+\|return [0-9]*\.[0-9]\+" "$file" | grep -v "return 0\|return 1\|return -1" || echo "")
    if [[ -n "$hardcoded_numbers" ]]; then
        file_issues+=("HARDCODED-NUMBER: Suspicious hardcoded numeric returns:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$hardcoded_numbers"
    fi
    
    # Fixed calculation results
    fixed_calculations=$(grep -n "return.*[0-9]\+.*[+\-\*/].*[0-9]\+" "$file" | grep -v "Math\.\|calculation\|compute" || echo "")
    if [[ -n "$fixed_calculations" ]]; then
        file_issues+=("FIXED-CALC: Hardcoded calculation results instead of computed values:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$fixed_calculations"
    fi
    
    if [[ ${#file_issues[@]} -gt 0 ]]; then
        printf '%s\n' "${file_issues[@]}"
        hardcoded_issues+=("$file: ${file_issues[0]}")
    else
        echo "  ✅ No hardcoded responses detected"
    fi
done

# Simulation and Fake Logic Detection
echo ""
echo "🤖 SIMULATION & FAKE LOGIC DETECTION"
echo "===================================="

simulation_issues=()

for file in "${production_files[@]}"; do
    echo ""
    echo "🔍 Scanning: $file"
    
    if [[ ! -f "$file" ]]; then
        continue
    fi
    
    file_issues=()
    
    # Keyword-based response systems (fake AI/intelligence)
    keyword_systems=$(grep -n -E "(if.*contains.*|if.*includes.*|switch.*keyword|match.*word)" "$file" | grep -E "(response|reply|answer|result)" || echo "")
    if [[ -n "$keyword_systems" ]]; then
        file_issues+=("FAKE-AI: Keyword-based response system detected (fake intelligence):")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$keyword_systems"
    fi
    
    # Pattern matching pretending to be understanding
    pattern_matching=$(grep -n -E "(regex.*response|pattern.*reply|match.*return.*)" "$file" | grep -v "validation\|format\|parse" || echo "")
    if [[ -n "$pattern_matching" ]]; then
        file_issues+=("FAKE-UNDERSTANDING: Pattern matching masquerading as understanding:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$pattern_matching"
    fi
    
    # Mock/stub code in production
    mock_in_production=$(grep -n -E "(mock|stub|fake|dummy).*[^t]est" "$file" | grep -v "import\|from\|@" || echo "")
    if [[ -n "$mock_in_production" ]]; then
        file_issues+=("MOCK-IN-PROD: Mock/stub implementations in production code:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$mock_in_production"
    fi
    
    # Random responses to mask hardcoding
    random_masking=$(grep -n -E "(Math\.random|Random\(\)|rand\(\)).*return|return.*random" "$file" || echo "")
    if [[ -n "$random_masking" ]]; then
        file_issues+=("RANDOM-MASK: Random values potentially masking hardcoded logic:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$random_masking"
    fi
    
    # Time-based responses (suspicious)
    time_based=$(grep -n -E "(Date\.now|new Date|getCurrentTime).*return|return.*time.*[0-9]" "$file" | grep -v "timestamp\|logging\|audit" || echo "")
    if [[ -n "$time_based" ]]; then
        file_issues+=("TIME-BASED: Time-based responses may be masking hardcoded behavior:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$time_based"
    fi
    
    if [[ ${#file_issues[@]} -gt 0 ]]; then
        printf '%s\n' "${file_issues[@]}"
        simulation_issues+=("$file: ${file_issues[0]}")
    else
        echo "  ✅ No simulation/fake logic detected"
    fi
done

# Shortcut and Bypass Code Detection
echo ""
echo "🏃 SHORTCUT & BYPASS CODE DETECTION"
echo "===================================="

shortcut_issues=()

for file in "${production_files[@]}"; do
    echo ""
    echo "🔍 Scanning: $file"
    
    if [[ ! -f "$file" ]]; then
        continue
    fi
    
    file_issues=()
    
    # Early returns with fake values
    early_returns=$(grep -n -A 2 "if.*return" "$file" | grep -E "return (true|false|null|0|\".*\"|\[\]|\{\})" | grep -v "error\|exception\|validation" || echo "")
    if [[ -n "$early_returns" ]]; then
        file_issues+=("EARLY-RETURN: Suspicious early returns with simple values:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$early_returns"
    fi
    
    # Debug modes in production
    debug_modes=$(grep -n -E "(if.*debug|if.*DEBUG|debug.*=.*true)" "$file" | grep -v "import\|console\|log" || echo "")
    if [[ -n "$debug_modes" ]]; then
        file_issues+=("DEBUG-MODE: Debug mode conditions found in production:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$debug_modes"
    fi
    
    # Test environment checks in production
    test_env_checks=$(grep -n -E "(if.*test|if.*TEST|NODE_ENV.*test)" "$file" | grep -v "import\|spec\|describe" || echo "")
    if [[ -n "$test_env_checks" ]]; then
        file_issues+=("TEST-ENV: Test environment checks in production code:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$test_env_checks"
    fi
    
    # Bypass conditionals
    bypass_conditions=$(grep -n -E "(if.*skip|if.*bypass|if.*ignore)" "$file" || echo "")
    if [[ -n "$bypass_conditions" ]]; then
        file_issues+=("BYPASS: Bypass conditions that may skip real processing:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$bypass_conditions"
    fi
    
    # TODO/FIXME left in production
    todo_fixme=$(grep -n -E "(TODO|FIXME|HACK|XXX)" "$file" || echo "")
    if [[ -n "$todo_fixme" ]]; then
        file_issues+=("INCOMPLETE: TODO/FIXME markers indicate incomplete implementation:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$todo_fixme"
    fi
    
    if [[ ${#file_issues[@]} -gt 0 ]]; then
        printf '%s\n' "${file_issues[@]}"
        shortcut_issues+=("$file: ${file_issues[0]}")
    else
        echo "  ✅ No shortcuts/bypasses detected"
    fi
done

# Deceptive Implementation Patterns
echo ""
echo "🎪 DECEPTIVE IMPLEMENTATION DETECTION"
echo "====================================="

deceptive_issues=()

for file in "${production_files[@]}"; do
    echo ""
    echo "🔍 Scanning: $file"
    
    if [[ ! -f "$file" ]]; then
        continue
    fi
    
    file_issues=()
    
    # Functions that behave differently based on caller
    caller_dependent=$(grep -n -E "(caller|stack|trace).*return|return.*caller" "$file" || echo "")
    if [[ -n "$caller_dependent" ]]; then
        file_issues+=("CALLER-DEPENDENT: Functions that behave differently based on caller:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$caller_dependent"
    fi
    
    # Environment-specific behavior (not configuration)
    env_specific=$(grep -n -E "(if.*NODE_ENV|if.*ENVIRONMENT|if.*ENV)" "$file" | grep -E "return.*different|return.*other" || echo "")
    if [[ -n "$env_specific" ]]; then
        file_issues+=("ENV-DEPENDENT: Different behavior in different environments:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$env_specific"
    fi
    
    # Clever algorithms that produce expected outputs without logic
    clever_algorithms=$(grep -n -E "(algorithm|formula|calculate)" "$file" | head -5)
    if [[ -n "$clever_algorithms" ]]; then
        # Check if these "algorithms" are actually just returning expected values
        while IFS= read -r algorithm_line; do
            [[ -z "$algorithm_line" ]] && continue
            line_num=$(echo "$algorithm_line" | cut -d: -f1)
            # Check next few lines for suspicious patterns
            context=$(sed -n "${line_num},$(($line_num + 10))p" "$file" 2>/dev/null)
            if echo "$context" | grep -q "return.*[0-9]*\.[0-9]*\|return.*[0-9]\+"; then
                file_issues+=("CLEVER-FAKE: Algorithm that may be producing expected outputs without real logic:")
                file_issues+=("  Context around line $line_num: $(echo "$context" | head -3 | tr '\n' ' ')")
            fi
        done <<< "$clever_algorithms"
    fi
    
    # Functions with suspiciously perfect outputs
    perfect_outputs=$(grep -n -E "return.*100|return.*1\.0|return.*success.*always" "$file" || echo "")
    if [[ -n "$perfect_outputs" ]]; then
        file_issues+=("PERFECT-OUTPUT: Suspiciously perfect return values:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$perfect_outputs"
    fi
    
    # Input-output mapping (lookup tables masquerading as logic)
    lookup_tables=$(grep -n -E "(lookup|mapping|dictionary.*return|map.*get.*return)" "$file" | grep -v "cache\|config\|translation" || echo "")
    if [[ -n "$lookup_tables" ]]; then
        file_issues+=("LOOKUP-TABLE: Lookup tables may be masquerading as complex logic:")
        while IFS= read -r line; do
            [[ -n "$line" ]] && file_issues+=("  Line: $line")
        done <<< "$lookup_tables"
    fi
    
    if [[ ${#file_issues[@]} -gt 0 ]]; then
        printf '%s\n' "${file_issues[@]}"
        deceptive_issues+=("$file: ${file_issues[0]}")
    else
        echo "  ✅ No deceptive patterns detected"
    fi
done

# Summary and Verdict
echo ""
echo "🚨 CHEAT DETECTION SUMMARY"
echo "==============================="

total_issues=$((${#hardcoded_issues[@]} + ${#simulation_issues[@]} + ${#shortcut_issues[@]} + ${#deceptive_issues[@]}))

echo "📊 Scan Results:"
echo "  Files scanned: ${#production_files[@]}"
echo "  Hardcoded response issues: ${#hardcoded_issues[@]}"
echo "  Simulation/fake logic issues: ${#simulation_issues[@]}"
echo "  Shortcut/bypass issues: ${#shortcut_issues[@]}"
echo "  Deceptive implementation issues: ${#deceptive_issues[@]}"
echo "  Total cheat violations: $total_issues"

# Generate detailed report if requested
if [[ -n "$report_file" ]] && [[ "$report_file" =~ ^--report= ]]; then
    report_path="${report_file#--report=}"
    echo ""
    echo "📄 Generating detailed report: $report_path"
    
    cat > "$report_path" << EOF
# Anti-Cheat Detection Report
Generated: $(date)
Scanned: $target_path
Language: ${language_filter:-"auto-detect"}
Files scanned: ${#production_files[@]}

## Summary
- Hardcoded response issues: ${#hardcoded_issues[@]}
- Simulation/fake logic issues: ${#simulation_issues[@]}
- Shortcut/bypass issues: ${#shortcut_issues[@]}
- Deceptive implementation issues: ${#deceptive_issues[@]}
- **Total violations: $total_issues**

## Detailed Findings

### Hardcoded Responses
$(printf '%s\n' "${hardcoded_issues[@]}")

### Simulation & Fake Logic
$(printf '%s\n' "${simulation_issues[@]}")

### Shortcuts & Bypasses
$(printf '%s\n' "${shortcut_issues[@]}")

### Deceptive Implementations
$(printf '%s\n' "${deceptive_issues[@]}")

## Recommendations
1. Replace all hardcoded responses with computed values
2. Remove simulation code that fakes intelligence or understanding
3. Implement proper logic instead of shortcuts and bypasses
4. Ensure all code represents genuine, working implementations
5. Add tests that verify real behavior, not fake responses
EOF
    
    echo "  ✅ Report generated: $report_path"
fi

echo ""
if [[ $total_issues -eq 0 ]]; then
    echo "🏆 CLEAN: No cheat patterns detected!"
    echo "   Code appears to contain genuine implementations"
    echo "   All logic appears to be real and working"
    exit 0
elif [[ $total_issues -le 5 ]]; then
    echo "⚠️ MINOR ISSUES: Few potential violations found"
    echo "   Review flagged code to ensure genuine implementation"
    echo "   Most code appears to be authentic"
    exit 1
elif [[ $total_issues -le 15 ]]; then
    echo "❌ SIGNIFICANT ISSUES: Multiple cheat patterns detected"
    echo "   Code contains hardcoded responses and simulation patterns"
    echo "   Major review and refactoring required"
    exit 2
else
    echo "🚨 MAJOR VIOLATIONS: Extensive cheat patterns detected"
    echo "   Code appears to contain substantial fake implementations"
    echo "   Complete rewrite may be necessary for production readiness"
    exit 3
fi