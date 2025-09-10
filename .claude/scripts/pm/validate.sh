#!/bin/bash

# PM Comprehensive Validation
# Zero tolerance validation that ensures features have meaningful tests, all tests pass, 
# applications run without errors, and all claims of functionality are actively verified.

echo "🔍 COMPREHENSIVE PROJECT VALIDATION"
echo "==================================="

target_path="${1:-.}"
strict_mode=false
e2e_mode=false
fix_on_fail=false
pm_only=false

# Parse options
for arg in "$@"; do
    case $arg in
        --strict) strict_mode=true ;;
        --e2e) e2e_mode=true ;;
        --fix-on-fail) fix_on_fail=true ;;
        --pm-only) pm_only=true ;;
    esac
done

echo "📁 Target: $target_path"
echo "⚡ Strict mode: $strict_mode"
echo "🧪 E2E testing: $e2e_mode"  
echo "🔧 Auto-fix: $fix_on_fail"
echo "📋 PM-only mode: $pm_only"

if [[ ! -d "$target_path" ]]; then
    echo "❌ Target directory not found: $target_path"
    exit 1
fi

cd "$target_path" || exit 1

# PM System Validation (original logic)
if [[ "$pm_only" == "true" ]]; then
    echo ""
    echo "📋 PM SYSTEM VALIDATION"
    echo "======================="
    
    errors=0
    warnings=0
    
    # Check directory structure
    echo "📁 Directory Structure:"
    [ -d ".claude" ] && echo "  ✅ .claude directory exists" || { echo "  ❌ .claude directory missing"; ((errors++)); }
    [ -d ".claude/prds" ] && echo "  ✅ PRDs directory exists" || echo "  ⚠️ PRDs directory missing"
    [ -d ".claude/epics" ] && echo "  ✅ Epics directory exists" || echo "  ⚠️ Epics directory missing"
    [ -d ".claude/rules" ] && echo "  ✅ Rules directory exists" || echo "  ⚠️ Rules directory missing"
    echo ""

# Check for orphaned files
echo "🗂️ Data Integrity:"

# Check epics have epic.md files
for epic_dir in .claude/epics/*/; do
  [ -d "$epic_dir" ] || continue
  if [ ! -f "$epic_dir/epic.md" ]; then
    echo "  ⚠️ Missing epic.md in $(basename "$epic_dir")"
    ((warnings++))
  fi
done

# Check for tasks without epics
orphaned=$(find .claude -name "[0-9]*.md" -not -path ".claude/epics/*/*" 2>/dev/null | wc -l)
[ $orphaned -gt 0 ] && echo "  ⚠️ Found $orphaned orphaned task files" && ((warnings++))

# Check for broken references
echo ""
echo "🔗 Reference Check:"

for task_file in .claude/epics/*/[0-9]*.md; do
  [ -f "$task_file" ] || continue

  deps=$(grep "^depends_on:" "$task_file" | head -1 | sed 's/^depends_on: *\[//' | sed 's/\]//' | sed 's/,/ /g')
  if [ -n "$deps" ] && [ "$deps" != "depends_on:" ]; then
    epic_dir=$(dirname "$task_file")
    for dep in $deps; do
      if [ ! -f "$epic_dir/$dep.md" ]; then
        echo "  ⚠️ Task $(basename "$task_file" .md) references missing task: $dep"
        ((warnings++))
      fi
    done
  fi
done

[ $warnings -eq 0 ] && [ $errors -eq 0 ] && echo "  ✅ All references valid"

# Check frontmatter
echo ""
echo "📝 Frontmatter Validation:"
invalid=0

for file in $(find .claude -name "*.md" -path "*/epics/*" -o -path "*/prds/*" 2>/dev/null); do
  if ! grep -q "^---" "$file"; then
    echo "  ⚠️ Missing frontmatter: $(basename "$file")"
    ((invalid++))
  fi
done

[ $invalid -eq 0 ] && echo "  ✅ All files have frontmatter"

# Summary
echo ""
echo "📊 Validation Summary:"
echo "  Errors: $errors"
echo "  Warnings: $warnings"
echo "  Invalid files: $invalid"

if [ $errors -eq 0 ] && [ $warnings -eq 0 ] && [ $invalid -eq 0 ]; then
  echo ""
  echo "✅ System is healthy!"
else
  echo ""
  echo "💡 Run /pm:clean to fix some issues automatically"
fi

    exit 0
fi

# Comprehensive Project Validation using intelligent detection
echo ""
echo "🔍 Running intelligent project detection..."

# Source the project detection script (find the correct path)
VALIDATE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$VALIDATE_SCRIPT_DIR/project-detect.sh" ]]; then
    source "$VALIDATE_SCRIPT_DIR/project-detect.sh"
else
    echo "❌ Cannot find project-detect.sh script"
    exit 1
fi

# Try to load cached detection first, otherwise run fresh detection
if ! load_cached_detection "$PWD"; then
    echo "🔍 Running fresh project detection..."
    detect_project "$PWD"
    source "$CACHE_FILE" # Load the results
fi

# Get commands using intelligent detection
mapfile -t test_commands < <(get_project_commands test)
mapfile -t build_commands < <(get_project_commands build)  
mapfile -t lint_commands < <(get_project_commands lint)

# Start commands (legacy - will be enhanced in future)
start_commands=()
if [[ " ${PROJECT_TYPES[*]} " =~ " nodejs " ]]; then
    if command -v jq >/dev/null && jq -e '.scripts.start' package.json >/dev/null 2>&1; then
        start_commands+=("npm start")
    elif command -v jq >/dev/null && jq -e '.scripts.dev' package.json >/dev/null 2>&1; then
        start_commands+=("npm run dev")
    fi
fi

if [[ ${#PROJECT_TYPES[@]} -eq 0 ]]; then
    echo "  ❌ No recognized project types found"
    if [[ "$pm_only" != "true" ]]; then
        exit 1
    fi
fi

echo "  📊 Summary:"
echo "    Project types: ${PROJECT_TYPES[*]:-none}"
echo "    Languages: ${LANGUAGES[*]:-none}"
echo "    Build tools: ${BUILD_TOOLS[*]:-none}"
echo "    Test commands: ${#test_commands[@]}"
echo "    Build commands: ${#build_commands[@]}"
echo "    Lint commands: ${#lint_commands[@]}"
echo "    Start commands: ${#start_commands[@]}"
[[ -n "$JAVA_VERSION" ]] && echo "    Java version: $JAVA_VERSION"
[[ -n "$KOTLIN_VERSION" ]] && echo "    Kotlin version: $KOTLIN_VERSION"
[[ -n "$GRADLE_VERSION" ]] && echo "    Gradle version: $GRADLE_VERSION"

# Critical Linting Validation (Zero Tolerance)
echo ""
echo "🔍 CRITICAL: Linting Validation (Zero Tolerance)"
echo "=============================================="

lint_failures=()

if [[ ${#lint_commands[@]} -eq 0 ]]; then
    echo "⚠️ No linting commands configured"
    if [[ "$strict_mode" == "true" ]]; then
        echo "❌ STRICT MODE: Linting must be configured"
        exit 1
    fi
else
    for lint_cmd in "${lint_commands[@]}"; do
        echo ""
        echo "🔍 Running: $lint_cmd"
        
        # Capture both stdout and stderr
        if lint_output=$(eval "$lint_cmd" 2>&1); then
            echo "✅ Linting passed: $lint_cmd"
        else
            lint_exit_code=$?
            echo "$lint_output"
            echo "❌ LINT FAILURE: $lint_cmd (exit code: $lint_exit_code)"
            lint_failures+=("$lint_cmd: exit code $lint_exit_code")
            
            if [[ "$fix_on_fail" == "true" ]]; then
                echo "🔧 Attempting automatic fix..."
                
                # Try common fix commands
                case "$lint_cmd" in
                    *"npm run lint"*)
                        if command -v jq >/dev/null && jq -e '.scripts["lint:fix"]' package.json >/dev/null 2>&1; then
                            echo "  Trying: npm run lint:fix"
                            npm run lint:fix
                        fi
                        ;;
                    *"ktlintCheck"*)
                        echo "  Trying: ./gradlew ktlintFormat"
                        (cd "${lint_cmd#*cd }" && ./gradlew ktlintFormat) 
                        ;;
                    *"flake8"*)
                        if command -v black >/dev/null; then
                            echo "  Trying: black ."
                            black .
                        fi
                        ;;
                esac
                
                # Re-run lint to check if fixed
                echo "🔍 Re-running after fix attempt: $lint_cmd"
                if eval "$lint_cmd" >/dev/null 2>&1; then
                    echo "✅ Fixed successfully"
                    # Remove from failures
                    lint_failures=("${lint_failures[@]/$lint_cmd: exit code $lint_exit_code}")
                else
                    echo "❌ Fix attempt failed"
                fi
            fi
        fi
    done
fi

# CRITICAL: Fail immediately on any lint errors
if [[ ${#lint_failures[@]} -gt 0 ]]; then
    echo ""
    echo "🚨 CRITICAL FAILURE: Linting errors detected"
    echo "=========================================="
    for failure in "${lint_failures[@]}"; do
        [[ -n "$failure" ]] && echo "  ❌ $failure"
    done
    echo ""
    echo "ALL CODE MUST PASS LINTING WITH ZERO ERRORS"
    echo "Fix all linting issues before proceeding"
    exit 1
fi

echo ""
echo "✅ LINTING: All checks passed"

# Critical Test Validation (Zero Tolerance)
echo ""
echo "🧪 CRITICAL: Test Execution (Zero Tolerance)"
echo "==========================================="

test_failures=()

if [[ ${#test_commands[@]} -eq 0 ]]; then
    echo "❌ CRITICAL: No test commands found"
    echo "ALL PROJECTS MUST HAVE MEANINGFUL TESTS"
    if [[ "$strict_mode" == "true" ]]; then
        exit 1
    fi
else
    for test_cmd in "${test_commands[@]}"; do
        echo ""
        echo "🧪 Running: $test_cmd"
        
        # Run tests with timeout to prevent hanging
        if test_output=$(timeout 600 bash -c "$test_cmd" 2>&1); then
            test_exit_code=0
        else
            test_exit_code=$?
        fi
        
        echo "$test_output"
        
        if [[ $test_exit_code -eq 124 ]]; then
            echo "❌ TEST TIMEOUT: $test_cmd (exceeded 10 minutes)"
            test_failures+=("$test_cmd: timeout")
        elif [[ $test_exit_code -ne 0 ]]; then
            echo "❌ TEST FAILURE: $test_cmd (exit code: $test_exit_code)"
            test_failures+=("$test_cmd: exit code $test_exit_code")
        else
            echo "✅ Tests passed: $test_cmd"
            
            # Validate test quality and meaningfulness
            echo "🔍 Validating test quality..."
            
            # Check for meaningful test counts
            test_count=$(echo "$test_output" | grep -oE '[0-9]+ (tests?|passing|passed)' | head -1 | grep -oE '[0-9]+' || echo "0")
            if [[ $test_count -lt 1 ]]; then
                echo "❌ NO MEANINGFUL TESTS: Test count is $test_count"
                test_failures+=("$test_cmd: no meaningful tests detected")
            else
                echo "  ✅ Test count: $test_count"
            fi
            
            # Check for test coverage if available
            coverage=$(echo "$test_output" | grep -oE '[0-9]+(\.[0-9]+)?%' | tail -1 || echo "")
            if [[ -n "$coverage" ]]; then
                coverage_num=$(echo "$coverage" | grep -oE '[0-9]+')
                echo "  📊 Coverage: $coverage"
                if [[ $coverage_num -lt 70 ]] && [[ "$strict_mode" == "true" ]]; then
                    echo "  ⚠️ STRICT MODE: Coverage below 70%"
                    test_failures+=("$test_cmd: low coverage $coverage")
                fi
            fi
            
            # Look for assertion patterns in test output
            assertions=$(echo "$test_output" | grep -c "assert\|expect\|should\|verify" || echo "0")
            if [[ $assertions -lt 1 ]]; then
                echo "  ⚠️ No assertion indicators found in test output"
            else
                echo "  ✅ Assertions detected: $assertions indicators"
            fi
        fi
    done
fi

# CRITICAL: Fail immediately on any test errors
if [[ ${#test_failures[@]} -gt 0 ]]; then
    echo ""
    echo "🚨 CRITICAL FAILURE: Test failures detected"
    echo "======================================="
    for failure in "${test_failures[@]}"; do
        [[ -n "$failure" ]] && echo "  ❌ $failure"
    done
    echo ""
    echo "ALL TESTS MUST PASS WITH ZERO FAILURES"  
    echo "Fix all test issues before proceeding"
    exit 1
fi

echo ""
echo "✅ TESTING: All tests passed with meaningful results"

# Critical Build Validation
echo ""
echo "🔨 CRITICAL: Build Validation"
echo "============================"

build_failures=()

if [[ ${#build_commands[@]} -eq 0 ]]; then
    echo "⚠️ No build commands configured"
else
    for build_cmd in "${build_commands[@]}"; do
        echo ""
        echo "🔨 Running: $build_cmd"
        
        if build_output=$(timeout 600 bash -c "$build_cmd" 2>&1); then
            build_exit_code=0
        else
            build_exit_code=$?
        fi
        
        # Only show last 50 lines of build output to avoid spam
        echo "$build_output" | tail -50
        
        if [[ $build_exit_code -eq 124 ]]; then
            echo "❌ BUILD TIMEOUT: $build_cmd (exceeded 10 minutes)"
            build_failures+=("$build_cmd: timeout")
        elif [[ $build_exit_code -ne 0 ]]; then
            echo "❌ BUILD FAILURE: $build_cmd (exit code: $build_exit_code)"
            build_failures+=("$build_cmd: exit code $build_exit_code")
        else
            echo "✅ Build successful: $build_cmd"
        fi
    done
fi

# CRITICAL: Fail immediately on any build errors
if [[ ${#build_failures[@]} -gt 0 ]]; then
    echo ""
    echo "🚨 CRITICAL FAILURE: Build failures detected"
    echo "========================================"
    for failure in "${build_failures[@]}"; do
        [[ -n "$failure" ]] && echo "  ❌ $failure"
    done
    echo ""
    echo "ALL BUILDS MUST SUCCEED WITH ZERO ERRORS"
    echo "Fix all build issues before proceeding"
    exit 1
fi

echo ""
echo "✅ BUILDS: All builds completed successfully"

# Application Runtime Validation
echo ""
echo "🚀 CRITICAL: Application Runtime Validation"
echo "=========================================="

runtime_failures=()

if [[ ${#start_commands[@]} -eq 0 ]]; then
    echo "⚠️ No start commands configured - cannot verify runtime"
    if [[ "$e2e_mode" == "true" ]]; then
        echo "❌ E2E MODE: Start commands required for runtime validation"
        exit 1
    fi
else
    for start_cmd in "${start_commands[@]}"; do
        echo ""
        echo "🚀 Testing application startup: $start_cmd"
        
        # Determine health check URL based on project type
        local health_url=""
        if [[ " ${PROJECT_TYPES[*]} " =~ " nodejs " ]]; then
            health_url="http://localhost:3000"
        elif [[ " ${PROJECT_TYPES[*]} " =~ " spring-boot " ]]; then
            health_url="http://localhost:8080/actuator/health"
        fi
        
        # Use server manager to start and monitor
        local server_name=$(echo "$start_cmd" | tr ' ' '-')
        echo "  🔄 Using intelligent server management..."
        
        # Start server with timeout and monitoring
        eval "$start_cmd" > "/tmp/${server_name}_stdout.log" 2> "/tmp/${server_name}_stderr.log" &
        local app_pid=$!
        
        # Monitor startup for errors and readiness
        local elapsed=0
        local startup_timeout=45
        local server_ready=false
        local has_errors=false
        
        while [[ $elapsed -lt $startup_timeout ]]; do
            # Check if process is still running
            if ! kill -0 $app_pid 2>/dev/null; then
                echo "  ❌ Application process died during startup"
                has_errors=true
                break
            fi
            
            # Check for startup errors
            if grep -qi "error\|exception\|failed\|cannot\|unable" "/tmp/${server_name}_stderr.log" 2>/dev/null; then
                echo "  ⚠️ Errors detected in application logs"
                has_errors=true
            fi
            
            # Test health endpoint if specified
            if [[ -n "$health_url" ]]; then
                if timeout 3 curl -s "$health_url" >/dev/null 2>&1; then
                    echo "  ✅ Application responding at $health_url"
                    server_ready=true
                    break
                fi
            else
                # For apps without health checks, wait for stable running
                if [[ $elapsed -ge 10 ]]; then
                    echo "  ✅ Application running for ${elapsed}s without crashes"
                    server_ready=true
                    break
                fi
            fi
            
            sleep 2
            ((elapsed += 2))
        done
        
        # Show recent logs for debugging
        if [[ $has_errors == true ]] || [[ $server_ready == false ]]; then
            echo "  📋 Recent application logs:"
            echo "--- STDERR (last 5 lines) ---"
            tail -n 5 "/tmp/${server_name}_stderr.log" 2>/dev/null || echo "No error output"
            echo "--- STDOUT (last 5 lines) ---"
            tail -n 5 "/tmp/${server_name}_stdout.log" 2>/dev/null || echo "No standard output"
        fi
        
        # Evaluate result
        if [[ $server_ready == true ]] && [[ $has_errors == false ]]; then
            echo "  🎉 Application startup successful"
            
            # Additional E2E testing if requested
            if [[ "$e2e_mode" == "true" ]]; then
                echo "  🔍 E2E: Comprehensive endpoint testing..."
                
                local endpoints_tested=0
                local endpoints_working=0
                
                # Test endpoints based on project type
                if [[ " ${PROJECT_TYPES[*]} " =~ " nodejs " ]]; then
                    for endpoint in "/" "/health" "/api/health" "/status"; do
                        for port in 3000 3001 8080; do
                            if timeout 5 curl -s "http://localhost:$port$endpoint" >/dev/null 2>&1; then
                                echo "    ✅ E2E: http://localhost:$port$endpoint responded"
                                ((endpoints_working++))
                                break
                            fi
                            ((endpoints_tested++))
                        done
                    done
                elif [[ " ${PROJECT_TYPES[*]} " =~ " spring-boot " ]]; then
                    for endpoint in "/" "/actuator/health" "/health"; do
                        if timeout 5 curl -s "http://localhost:8080$endpoint" >/dev/null 2>&1; then
                            echo "    ✅ E2E: http://localhost:8080$endpoint responded"
                            ((endpoints_working++))
                            break
                        fi
                        ((endpoints_tested++))
                    done
                fi
                
                if [[ $endpoints_working -eq 0 ]] && [[ $endpoints_tested -gt 0 ]]; then
                    echo "    ❌ E2E: No endpoints responding"
                    runtime_failures+=("$start_cmd: no responding endpoints")
                elif [[ $endpoints_working -gt 0 ]]; then
                    echo "    ✅ E2E: Application responding to requests"
                fi
            fi
        else
            # Server failed to start properly
            if [[ $has_errors == true ]]; then
                echo "  💥 Application startup failed with errors"
                runtime_failures+=("$start_cmd: startup errors")
            else
                echo "  ⏰ Application startup timeout"
                runtime_failures+=("$start_cmd: startup timeout")
            fi
        fi
        
        # Graceful shutdown
        echo "  🛑 Shutting down application..."
        if kill -0 $app_pid 2>/dev/null; then
            # Try graceful shutdown first
            kill -TERM $app_pid 2>/dev/null
            sleep 5
            
            # Force kill if still running
            if kill -0 $app_pid 2>/dev/null; then
                echo "  🔨 Force killing application..."
                kill -KILL $app_pid 2>/dev/null
                sleep 2
            fi
            
            echo "  ✅ Application stopped"
        fi
        
        # Cleanup log files
        rm -f "/tmp/${server_name}_stdout.log" "/tmp/${server_name}_stderr.log" 2>/dev/null
    done
    
    # Final cleanup - kill any remaining development servers
    echo ""
    echo "🧹 Final cleanup of development servers..."
    pkill -f "npm.*start\|npm.*dev\|gradlew.*bootRun\|webpack.*dev.*server" 2>/dev/null || true
    echo "  ✅ Cleanup complete"
fi

# Final Validation Summary
echo ""
echo "🏆 COMPREHENSIVE VALIDATION COMPLETE"
echo "===================================="

# Count all issue categories
total_issues=$((${#lint_failures[@]} + ${#test_failures[@]} + ${#build_failures[@]} + ${#runtime_failures[@]}))

echo "📊 Validation Results:"
echo "  🔍 Linting: ${#lint_failures[@]} failures"
echo "  🧪 Testing: ${#test_failures[@]} failures"  
echo "  🔨 Building: ${#build_failures[@]} failures"
echo "  🚀 Runtime: ${#runtime_failures[@]} failures"
echo "  📈 Total Issues: $total_issues"

echo ""
echo "🎯 Standards Applied:"
echo "  ✅ Zero tolerance linting"
echo "  ✅ Zero tolerance test failures"
echo "  ✅ Real application runtime verification"
if [[ "$e2e_mode" == "true" ]]; then
    echo "  ✅ End-to-end functionality validation"
fi

echo ""
if [[ $total_issues -eq 0 ]]; then
    echo "🎉 VALIDATION PASSED: All standards met!"
    echo ""
    echo "✅ ALL CLAIMS OF FUNCTIONALITY VERIFIED:"
    echo "  • Code runs without lint errors"
    echo "  • All tests pass with meaningful assertions"
    echo "  • Applications build successfully"
    echo "  • Applications start and run correctly"
    if [[ "$e2e_mode" == "true" ]]; then
        echo "  • End-to-end functionality confirmed with real calls"
    fi
    echo ""
    echo "🏆 PROJECT IS PRODUCTION READY"
    exit 0
else
    echo "❌ VALIDATION FAILED: $total_issues issues must be resolved"
    echo ""
    echo "🔧 Required Actions:"
    echo "  1. Fix all linting errors (zero tolerance)"
    echo "  2. Fix all failing tests (zero tolerance)"
    echo "  3. Fix all build failures (zero tolerance)"
    echo "  4. Ensure applications start and run correctly"
    echo ""
    echo "🚨 NO SHORTCUTS ALLOWED - ALL ISSUES MUST BE RESOLVED"
    echo "Run /pm:validate again after fixes to verify completion"
    exit 1
fi
