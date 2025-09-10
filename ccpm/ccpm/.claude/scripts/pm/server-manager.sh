#!/bin/bash

# Server Manager for PM System
# Handles lifecycle of development servers (start, health check, error detection, cleanup)

# Function to start a server and monitor it
start_and_monitor_server() {
    local start_command="$1"
    local server_name="${2:-server}"
    local timeout_seconds="${3:-30}"
    local health_check_url="${4:-http://localhost:3000}"
    
    echo "🚀 Starting $server_name..."
    echo "   Command: $start_command"
    
    # Create log files
    local stdout_log="/tmp/${server_name}_stdout.log"
    local stderr_log="/tmp/${server_name}_stderr.log"
    
    # Start server in background and capture PID
    eval "$start_command" > "$stdout_log" 2> "$stderr_log" &
    local server_pid=$!
    
    echo "   PID: $server_pid"
    echo "   Logs: $stdout_log, $stderr_log"
    
    # Wait for server to start and check for errors
    local elapsed=0
    local server_ready=false
    local has_errors=false
    
    while [[ $elapsed -lt $timeout_seconds ]]; do
        # Check if process is still running
        if ! kill -0 $server_pid 2>/dev/null; then
            echo "   ❌ Server process died"
            has_errors=true
            break
        fi
        
        # Check for error indicators in logs
        if grep -qi "error\|exception\|failed\|cannot\|unable" "$stderr_log" 2>/dev/null; then
            echo "   ⚠️ Errors detected in server logs"
            has_errors=true
        fi
        
        # Try health check (if URL provided)
        if [[ -n "$health_check_url" ]]; then
            if timeout 3 curl -s "$health_check_url" >/dev/null 2>&1; then
                echo "   ✅ Server responding at $health_check_url"
                server_ready=true
                break
            fi
        else
            # If no URL, just check if it's been running for a few seconds
            if [[ $elapsed -ge 5 ]]; then
                echo "   ✅ Server has been running for ${elapsed}s"
                server_ready=true
                break
            fi
        fi
        
        sleep 2
        ((elapsed += 2))
        echo "   ⏳ Waiting for server... (${elapsed}s)"
    done
    
    # Show server status
    if [[ $server_ready == true ]] && [[ $has_errors == false ]]; then
        echo "   🎉 Server started successfully"
        server_status="running"
    elif [[ $has_errors == true ]]; then
        echo "   💥 Server has errors"
        server_status="error"
    else
        echo "   ⏰ Server startup timeout"
        server_status="timeout"
    fi
    
    # Show recent logs
    echo ""
    echo "📋 Recent Server Output (last 10 lines):"
    echo "--- STDOUT ---"
    tail -n 10 "$stdout_log" 2>/dev/null || echo "No stdout output"
    echo "--- STDERR ---" 
    tail -n 10 "$stderr_log" 2>/dev/null || echo "No stderr output"
    echo ""
    
    # Return PID and status
    echo "$server_pid:$server_status:$stdout_log:$stderr_log"
}

# Function to stop a server gracefully
stop_server() {
    local server_pid="$1"
    local server_name="${2:-server}"
    local force_timeout="${3:-10}"
    
    if [[ -z "$server_pid" ]] || ! kill -0 "$server_pid" 2>/dev/null; then
        echo "🛑 Server $server_name (PID: $server_pid) is not running"
        return 0
    fi
    
    echo "🛑 Stopping $server_name (PID: $server_pid)..."
    
    # Try graceful shutdown first
    echo "   Sending SIGTERM..."
    kill -TERM "$server_pid" 2>/dev/null
    
    # Wait for graceful shutdown
    local elapsed=0
    while [[ $elapsed -lt $force_timeout ]]; do
        if ! kill -0 "$server_pid" 2>/dev/null; then
            echo "   ✅ Server stopped gracefully"
            return 0
        fi
        sleep 1
        ((elapsed += 1))
    done
    
    # Force kill if needed
    echo "   Forcing shutdown with SIGKILL..."
    kill -KILL "$server_pid" 2>/dev/null
    sleep 2
    
    if ! kill -0 "$server_pid" 2>/dev/null; then
        echo "   ✅ Server force-stopped"
        return 0
    else
        echo "   ❌ Failed to stop server"
        return 1
    fi
}

# Function to test multiple server configurations
test_server_configurations() {
    local project_type="$1"
    local test_results=()
    
    case "$project_type" in
        "nodejs")
            # Test common Node.js server configurations
            if [[ -f "package.json" ]]; then
                # Check for start scripts
                if jq -e '.scripts.start' package.json >/dev/null 2>&1; then
                    local start_cmd=$(jq -r '.scripts.start' package.json)
                    echo "🧪 Testing npm start: $start_cmd"
                    
                    local result=$(start_and_monitor_server "npm start" "npm-start" 30)
                    local pid=$(echo "$result" | cut -d':' -f1)
                    local status=$(echo "$result" | cut -d':' -f2)
                    
                    test_results+=("npm start:$status")
                    
                    if [[ "$status" == "running" ]]; then
                        stop_server "$pid" "npm-start"
                    fi
                fi
                
                # Check for dev scripts
                if jq -e '.scripts.dev' package.json >/dev/null 2>&1; then
                    local dev_cmd=$(jq -r '.scripts.dev' package.json)
                    echo "🧪 Testing npm run dev: $dev_cmd"
                    
                    local result=$(start_and_monitor_server "npm run dev" "npm-dev" 30)
                    local pid=$(echo "$result" | cut -d':' -f1)
                    local status=$(echo "$result" | cut -d':' -f2)
                    
                    test_results+=("npm run dev:$status")
                    
                    if [[ "$status" == "running" ]]; then
                        stop_server "$pid" "npm-dev"
                    fi
                fi
            fi
            ;;
            
        "gradle")
            # Test Gradle bootRun for Spring Boot projects
            if grep -q "spring-boot" build.gradle* 2>/dev/null; then
                echo "🧪 Testing Spring Boot application..."
                
                local gradle_cmd="./gradlew bootRun"
                [[ ! -x "./gradlew" ]] && gradle_cmd="gradle bootRun"
                
                local result=$(start_and_monitor_server "$gradle_cmd" "spring-boot" 60 "http://localhost:8080")
                local pid=$(echo "$result" | cut -d':' -f1)
                local status=$(echo "$result" | cut -d':' -f2)
                
                test_results+=("gradle bootRun:$status")
                
                if [[ "$status" == "running" ]]; then
                    stop_server "$pid" "spring-boot"
                fi
            fi
            ;;
    esac
    
    # Summary
    echo ""
    echo "📊 Server Testing Summary:"
    for result in "${test_results[@]}"; do
        local cmd=$(echo "$result" | cut -d':' -f1)
        local status=$(echo "$result" | cut -d':' -f2)
        
        case "$status" in
            "running") echo "  ✅ $cmd: SUCCESS" ;;
            "error") echo "  ❌ $cmd: ERRORS DETECTED" ;;
            "timeout") echo "  ⏰ $cmd: TIMEOUT" ;;
            *) echo "  ❓ $cmd: UNKNOWN" ;;
        esac
    done
    
    return 0
}

# Function to clean up any leftover processes
cleanup_servers() {
    echo "🧹 Cleaning up any leftover server processes..."
    
    # Kill common development server processes
    pkill -f "npm.*start\|npm.*dev\|gradlew.*bootRun\|webpack.*dev.*server" 2>/dev/null || true
    
    # Clean up log files older than 1 hour
    find /tmp -name "*_stdout.log" -o -name "*_stderr.log" -mmin +60 -delete 2>/dev/null || true
    
    echo "   ✅ Cleanup complete"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    command="$1"
    shift
    
    case "$command" in
        "start")
            start_and_monitor_server "$@"
            ;;
        "stop")
            stop_server "$@"
            ;;
        "test")
            test_server_configurations "$@"
            ;;
        "cleanup")
            cleanup_servers
            ;;
        *)
            echo "Usage: $0 {start|stop|test|cleanup}"
            echo "  start <command> [name] [timeout] [health_url] - Start and monitor a server"
            echo "  stop <pid> [name] [timeout] - Stop a server gracefully"
            echo "  test <project_type> - Test server configurations for a project type"
            echo "  cleanup - Clean up leftover processes and logs"
            exit 1
            ;;
    esac
fi