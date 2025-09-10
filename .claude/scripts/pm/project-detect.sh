#!/bin/bash

# PM Project Detection
# Intelligent project detection and caching system

CACHE_FILE=".claude/.project-detection-cache"

# Function to detect project characteristics
detect_project() {
    local project_path="$1"
    local cache_key="$project_path"
    
    echo "🔍 Analyzing project structure: $project_path"
    
    # Initialize project info
    local project_types=()
    local languages=()
    local build_tools=()
    local test_frameworks=()
    local lint_tools=()
    local java_version=""
    local kotlin_version=""
    local gradle_version=""
    
    # Change to project directory
    cd "$project_path" || return 1
    
    # Check for package.json (Node.js/TypeScript)
    if [[ -f "package.json" ]]; then
        project_types+=("nodejs")
        
        # Check if TypeScript
        if jq -e '.devDependencies.typescript // .dependencies.typescript' package.json >/dev/null 2>&1; then
            languages+=("typescript")
        elif find . -name "*.ts" -not -path "*/node_modules/*" | head -1 | grep -q "."; then
            languages+=("typescript")
        else
            languages+=("javascript")
        fi
        
        # Check for test frameworks
        if jq -e '.devDependencies.jest // .dependencies.jest' package.json >/dev/null 2>&1; then
            test_frameworks+=("jest")
        fi
        if jq -e '.devDependencies.mocha // .dependencies.mocha' package.json >/dev/null 2>&1; then
            test_frameworks+=("mocha")
        fi
        
        # Check for linting tools
        if jq -e '.devDependencies.eslint // .dependencies.eslint' package.json >/dev/null 2>&1; then
            lint_tools+=("eslint")
        fi
        if jq -e '.devDependencies.prettier // .dependencies.prettier' package.json >/dev/null 2>&1; then
            lint_tools+=("prettier")
        fi
        
        build_tools+=("npm")
    fi
    
    # Check for Gradle projects
    if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]] || [[ -f "settings.gradle" ]] || [[ -f "settings.gradle.kts" ]]; then
        project_types+=("gradle")
        build_tools+=("gradle")
        
        # Get Gradle version
        if command -v ./gradlew >/dev/null; then
            gradle_version=$(./gradlew --version 2>/dev/null | grep "Gradle " | sed 's/Gradle //')
        elif command -v gradle >/dev/null; then
            gradle_version=$(gradle --version 2>/dev/null | grep "Gradle " | sed 's/Gradle //')
        fi
        
        # Check build files for project type indicators
        local build_files=""
        [[ -f "build.gradle" ]] && build_files+=" build.gradle"
        [[ -f "build.gradle.kts" ]] && build_files+=" build.gradle.kts"
        [[ -f "settings.gradle" ]] && build_files+=" settings.gradle"
        [[ -f "settings.gradle.kts" ]] && build_files+=" settings.gradle.kts"
        
        # Analyze build files for plugins and dependencies
        local build_content=""
        for file in $build_files; do
            [[ -f "$file" ]] && build_content+=" $(cat "$file")"
        done
        
        # Check for Kotlin
        if echo "$build_content" | grep -q "kotlin\|org.jetbrains.kotlin"; then
            languages+=("kotlin")
            
            # Try to get Kotlin version
            kotlin_version=$(echo "$build_content" | grep -o "kotlin.*['\"].*['\"]" | head -1 | sed "s/.*['\"]\\(.*\\)['\"].*/\\1/" || echo "")
            
            # Check if it's Kotlin Multiplatform
            if echo "$build_content" | grep -q "kotlin-multiplatform\|org.jetbrains.kotlin.multiplatform"; then
                project_types+=("kotlin-multiplatform")
            else
                project_types+=("kotlin")
            fi
        fi
        
        # Check for Java
        if echo "$build_content" | grep -q "java\|JavaPlugin\|java-library" || find . -name "*.java" -not -path "*/build/*" | head -1 | grep -q "."; then
            languages+=("java")
            
            # Try to get Java version from build files
            java_version=$(echo "$build_content" | grep -o "sourceCompatibility.*=.*[0-9]\\+\|JavaVersion.VERSION_[0-9_]*\|jvmTarget.*=.*['\"][0-9]*['\"]" | head -1 | grep -o "[0-9]\\+" || echo "")
            
            # If not found in build files, check system
            if [[ -z "$java_version" ]] && command -v java >/dev/null; then
                java_version=$(java -version 2>&1 | grep "version" | head -1 | sed 's/.*version "\\([0-9]*\\).*/\\1/')
            fi
            
            project_types+=("java")
        fi
        
        # Check for Android
        if echo "$build_content" | grep -q "android\|com.android"; then
            project_types+=("android")
        fi
        
        # Check for Spring Boot
        if echo "$build_content" | grep -q "spring-boot\|org.springframework.boot"; then
            project_types+=("spring-boot")
        fi
        
        # Check for available linting/analysis tools
        
        # Check for ktlint
        if echo "$build_content" | grep -q "ktlint" || command -v ktlint >/dev/null; then
            lint_tools+=("ktlint")
        fi
        
        # Check for detekt
        if echo "$build_content" | grep -q "detekt\|io.gitlab.arturbosch.detekt"; then
            lint_tools+=("detekt")
        fi
        
        # Check for checkstyle
        if echo "$build_content" | grep -q "checkstyle" || (command -v ./gradlew >/dev/null && ./gradlew tasks 2>/dev/null | grep -q "checkstyle"); then
            lint_tools+=("checkstyle")
        fi
        
        # Check for SpotBugs
        if echo "$build_content" | grep -q "spotbugs"; then
            lint_tools+=("spotbugs")
        fi
        
        # Check for test frameworks
        if echo "$build_content" | grep -q "junit"; then
            test_frameworks+=("junit")
        fi
        if echo "$build_content" | grep -q "testng"; then
            test_frameworks+=("testng")
        fi
        if echo "$build_content" | grep -q "spek"; then
            test_frameworks+=("spek")
        fi
    fi
    
    # Check for Maven projects
    if [[ -f "pom.xml" ]]; then
        project_types+=("maven")
        build_tools+=("maven")
        
        # Analyze pom.xml
        if grep -q "kotlin" pom.xml; then
            languages+=("kotlin")
        fi
        if grep -q "java" pom.xml || find . -name "*.java" -not -path "*/target/*" | head -1 | grep -q "."; then
            languages+=("java")
        fi
    fi
    
    # Check for Python projects
    if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        project_types+=("python")
        languages+=("python")
        
        # Check for Python linting tools
        if command -v flake8 >/dev/null; then
            lint_tools+=("flake8")
        fi
        if command -v black >/dev/null; then
            lint_tools+=("black")
        fi
        if command -v pylint >/dev/null; then
            lint_tools+=("pylint")
        fi
        
        # Check for test frameworks
        if [[ -f "requirements.txt" ]] && grep -q "pytest" requirements.txt; then
            test_frameworks+=("pytest")
        elif command -v pytest >/dev/null; then
            test_frameworks+=("pytest")
        fi
    fi
    
    # Check for Rust projects
    if [[ -f "Cargo.toml" ]]; then
        project_types+=("rust")
        languages+=("rust")
        build_tools+=("cargo")
    fi
    
    # Check for Go projects
    if [[ -f "go.mod" ]] || [[ -f "go.sum" ]]; then
        project_types+=("go")
        languages+=("go")
        build_tools+=("go")
    fi
    
    # Generate cache entry
    local cache_entry=""
    cache_entry+="PROJECT_TYPES=($(printf '%s ' "${project_types[@]}"))\n"
    cache_entry+="LANGUAGES=($(printf '%s ' "${languages[@]}"))\n"
    cache_entry+="BUILD_TOOLS=($(printf '%s ' "${build_tools[@]}"))\n"
    cache_entry+="TEST_FRAMEWORKS=($(printf '%s ' "${test_frameworks[@]}"))\n"
    cache_entry+="LINT_TOOLS=($(printf '%s ' "${lint_tools[@]}"))\n"
    cache_entry+="JAVA_VERSION=\"$java_version\"\n"
    cache_entry+="KOTLIN_VERSION=\"$kotlin_version\"\n"
    cache_entry+="GRADLE_VERSION=\"$gradle_version\"\n"
    cache_entry+="DETECTED_AT=\"$(date -Iseconds)\"\n"
    cache_entry+="PROJECT_PATH=\"$project_path\"\n"
    
    # Save to cache
    mkdir -p "$(dirname "$CACHE_FILE")"
    echo "# Project Detection Cache Entry for: $cache_key" > "$CACHE_FILE"
    echo -e "$cache_entry" >> "$CACHE_FILE"
    
    # Output results
    echo "📊 Project Detection Results:"
    echo "  Project Types: ${project_types[*]:-none}"
    echo "  Languages: ${languages[*]:-none}"
    echo "  Build Tools: ${build_tools[*]:-none}"
    echo "  Test Frameworks: ${test_frameworks[*]:-none}"
    echo "  Lint Tools: ${lint_tools[*]:-none}"
    [[ -n "$java_version" ]] && echo "  Java Version: $java_version"
    [[ -n "$kotlin_version" ]] && echo "  Kotlin Version: $kotlin_version"
    [[ -n "$gradle_version" ]] && echo "  Gradle Version: $gradle_version"
    
    return 0
}

# Function to load cached detection
load_cached_detection() {
    local project_path="$1"
    
    if [[ -f "$CACHE_FILE" ]]; then
        # Check if cache is for current project and not too old
        local cached_path=$(grep "PROJECT_PATH=" "$CACHE_FILE" | cut -d'"' -f2)
        local cache_date=$(grep "DETECTED_AT=" "$CACHE_FILE" | cut -d'"' -f2)
        
        if [[ "$cached_path" == "$project_path" ]]; then
            # Check if cache is less than 1 hour old
            local cache_timestamp=$(date -d "$cache_date" +%s 2>/dev/null || echo "0")
            local current_timestamp=$(date +%s)
            local age=$((current_timestamp - cache_timestamp))
            
            if [[ $age -lt 3600 ]]; then
                echo "📋 Using cached project detection ($(($age / 60))m old)"
                source "$CACHE_FILE"
                
                echo "📊 Cached Project Info:"
                echo "  Project Types: ${PROJECT_TYPES[*]:-none}"
                echo "  Languages: ${LANGUAGES[*]:-none}"
                echo "  Build Tools: ${BUILD_TOOLS[*]:-none}"
                echo "  Test Frameworks: ${TEST_FRAMEWORKS[*]:-none}"
                echo "  Lint Tools: ${LINT_TOOLS[*]:-none}"
                [[ -n "$JAVA_VERSION" ]] && echo "  Java Version: $JAVA_VERSION"
                [[ -n "$KOTLIN_VERSION" ]] && echo "  Kotlin Version: $KOTLIN_VERSION"
                [[ -n "$GRADLE_VERSION" ]] && echo "  Gradle Version: $GRADLE_VERSION"
                
                return 0
            fi
        fi
    fi
    
    return 1
}

# Function to get project commands based on detection
get_project_commands() {
    local command_type="$1" # test, build, lint
    local commands=()
    
    case "$command_type" in
        "test")
            # Node.js/TypeScript
            if [[ " ${PROJECT_TYPES[*]} " =~ " nodejs " ]]; then
                if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
                    commands+=("npm test")
                fi
            fi
            
            # Gradle projects
            if [[ " ${PROJECT_TYPES[*]} " =~ " gradle " ]]; then
                if command -v ./gradlew >/dev/null; then
                    commands+=("./gradlew test")
                elif command -v gradle >/dev/null; then
                    commands+=("gradle test")
                fi
            fi
            
            # Maven projects
            if [[ " ${PROJECT_TYPES[*]} " =~ " maven " ]]; then
                commands+=("mvn test")
            fi
            
            # Python projects
            if [[ " ${PROJECT_TYPES[*]} " =~ " python " ]]; then
                if [[ " ${TEST_FRAMEWORKS[*]} " =~ " pytest " ]]; then
                    commands+=("python -m pytest")
                else
                    commands+=("python -m unittest")
                fi
            fi
            
            # Rust projects
            if [[ " ${PROJECT_TYPES[*]} " =~ " rust " ]]; then
                commands+=("cargo test")
            fi
            
            # Go projects
            if [[ " ${PROJECT_TYPES[*]} " =~ " go " ]]; then
                commands+=("go test ./...")
            fi
            ;;
            
        "build")
            # Node.js/TypeScript
            if [[ " ${PROJECT_TYPES[*]} " =~ " nodejs " ]]; then
                if jq -e '.scripts.build' package.json >/dev/null 2>&1; then
                    commands+=("npm run build")
                fi
            fi
            
            # Gradle projects
            if [[ " ${PROJECT_TYPES[*]} " =~ " gradle " ]]; then
                if command -v ./gradlew >/dev/null; then
                    commands+=("./gradlew build")
                elif command -v gradle >/dev/null; then
                    commands+=("gradle build")
                fi
            fi
            
            # Maven projects
            if [[ " ${PROJECT_TYPES[*]} " =~ " maven " ]]; then
                commands+=("mvn compile")
            fi
            
            # Rust projects
            if [[ " ${PROJECT_TYPES[*]} " =~ " rust " ]]; then
                commands+=("cargo build")
            fi
            
            # Go projects
            if [[ " ${PROJECT_TYPES[*]} " =~ " go " ]]; then
                commands+=("go build ./...")
            fi
            ;;
            
        "lint")
            # Node.js/TypeScript
            if [[ " ${PROJECT_TYPES[*]} " =~ " nodejs " ]]; then
                if [[ " ${LINT_TOOLS[*]} " =~ " eslint " ]]; then
                    commands+=("npm run lint" "npx eslint .")
                fi
                if [[ " ${LINT_TOOLS[*]} " =~ " prettier " ]]; then
                    commands+=("npx prettier --check .")
                fi
            fi
            
            # Gradle projects with Kotlin
            if [[ " ${PROJECT_TYPES[*]} " =~ " gradle " ]] && [[ " ${LANGUAGES[*]} " =~ " kotlin " ]]; then
                if [[ " ${LINT_TOOLS[*]} " =~ " ktlint " ]]; then
                    if command -v ./gradlew >/dev/null; then
                        commands+=("./gradlew ktlintCheck")
                    fi
                fi
                if [[ " ${LINT_TOOLS[*]} " =~ " detekt " ]]; then
                    if command -v ./gradlew >/dev/null; then
                        commands+=("./gradlew detekt")
                    fi
                fi
            fi
            
            # Gradle projects with Java
            if [[ " ${PROJECT_TYPES[*]} " =~ " gradle " ]] && [[ " ${LANGUAGES[*]} " =~ " java " ]]; then
                if [[ " ${LINT_TOOLS[*]} " =~ " checkstyle " ]]; then
                    if command -v ./gradlew >/dev/null; then
                        commands+=("./gradlew checkstyleMain")
                    fi
                fi
                if [[ " ${LINT_TOOLS[*]} " =~ " spotbugs " ]]; then
                    if command -v ./gradlew >/dev/null; then
                        commands+=("./gradlew spotbugsMain")
                    fi
                fi
            fi
            
            # Python projects
            if [[ " ${PROJECT_TYPES[*]} " =~ " python " ]]; then
                if [[ " ${LINT_TOOLS[*]} " =~ " flake8 " ]]; then
                    commands+=("flake8 .")
                fi
                if [[ " ${LINT_TOOLS[*]} " =~ " black " ]]; then
                    commands+=("black --check .")
                fi
                if [[ " ${LINT_TOOLS[*]} " =~ " pylint " ]]; then
                    commands+=("pylint .")
                fi
            fi
            
            # Rust projects
            if [[ " ${PROJECT_TYPES[*]} " =~ " rust " ]]; then
                commands+=("cargo clippy")
            fi
            
            # Go projects
            if [[ " ${PROJECT_TYPES[*]} " =~ " go " ]]; then
                commands+=("go vet ./..." "golint ./...")
            fi
            ;;
    esac
    
    printf '%s\n' "${commands[@]}"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    target_path="${1:-.}"
    force_detect="${2}"
    
    # Change to target directory
    cd "$target_path" || exit 1
    
    # Try to load from cache first
    if [[ "$force_detect" != "--force" ]] && load_cached_detection "$PWD"; then
        echo "✅ Project detection loaded from cache"
    else
        echo "🔍 Running fresh project detection..."
        detect_project "$PWD"
    fi
    
    # If requested, show available commands
    if [[ "$3" == "--show-commands" ]]; then
        echo ""
        echo "🛠️ Available Commands:"
        echo "  Test: $(get_project_commands test | tr '\n' ', ' | sed 's/,$//')"
        echo "  Build: $(get_project_commands build | tr '\n' ', ' | sed 's/,$//')"
        echo "  Lint: $(get_project_commands lint | tr '\n' ', ' | sed 's/,$//')"
    fi
fi