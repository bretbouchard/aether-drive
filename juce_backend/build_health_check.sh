#!/bin/bash
################################################################################
# White Room Plugin Build Health Check
#
# This script monitors the build health of all 13 plugins and generates a
# build score (0-100%) based on compilation success, warnings, and errors.
#
# Usage:
#   ./build_health_check.sh              # Check all plugins
#   ./build_health_check.sh --verbose    # Detailed output
#   ./build_health_check.sh --json       # JSON output for CI/CD
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JUCE_BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${JUCE_BACKEND_DIR}/build_health_check"
VERBOSE=false
OUTPUT_FORMAT="text"

# Plugin list (all 13 plugins)
declare -A PLUGINS=(
    ["aether_giant_horns_plugin_build"]="Aether Giant Horns"
    ["aether_giant_voice_plugin_build"]="Aether Giant Voice"
    ["aetherdrive_plugin_build"]="Aether Drive"
    ["drummachine_plugin_build"]="Drum Machine"
    ["farfaraway_plugin_build"]="Far Far Away"
    ["filtergate_plugin_build"]="FilterGate"
    ["giant_instruments_plugin_build"]="Giant Instruments"
    ["kane_marco_aether_string_plugin_build"]="Kane Marco Aether String"
    ["kane_marco_plugin_build"]="Kane Marco"
    ["localgal_plugin_build"]="Local Galaxy"
    ["monument_plugin_build"]="Monument"
    ["nex_synth_plugin_build"]="Nex Synth"
    ["sam_sampler_plugin_build"]="Sam Sampler"
)

# Results storage
declare -A BUILD_STATUS
declare -A BUILD_WARNINGS
declare -A BUILD_ERRORS
declare -A BUILD_TIME

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                VERBOSE=true
                shift
                ;;
            --json)
                OUTPUT_FORMAT="json"
                shift
                ;;
            --help)
                echo "Usage: $0 [--verbose] [--json]"
                echo "  --verbose  Show detailed build output"
                echo "  --json     Output results in JSON format"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

print_header() {
    if [ "$OUTPUT_FORMAT" = "text" ]; then
        echo ""
        echo "=========================================="
        echo "  White Room Plugin Build Health Check"
        echo "=========================================="
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Build Dir: ${BUILD_DIR}"
        echo ""
    fi
}

################################################################################
# Build Functions
################################################################################

build_plugin() {
    local plugin_dir="$1"
    local plugin_name="$2"
    local build_start=$(date +%s)

    log_info "Building ${plugin_name}..."

    local plugin_build_dir="${BUILD_DIR}/${plugin_dir}"
    mkdir -p "${plugin_build_dir}"

    # Configure
    if ! cmake -B "${plugin_build_dir}" \
            -DCMAKE_BUILD_TYPE=Release \
            -DBUILD_VST3=ON \
            -DBUILD_AU=OFF \
            -DBUILD_CLAP=ON \
            -DBUILD_STANDALONE=OFF \
            "${JUCE_BACKEND_DIR}/${plugin_dir}" > /dev/null 2>&1; then
        BUILD_STATUS[$plugin_name]="FAILED"
        BUILD_ERRORS[$plugin_name]="CMake configuration failed"
        return 1
    fi

    # Build
    local build_output
    if ! build_output=$(cmake --build "${plugin_build_dir}" --config Release -j8 2>&1); then
        BUILD_STATUS[$plugin_name]="FAILED"

        # Count errors and warnings
        local error_count=$(echo "$build_output" | grep -c "error:" || true)
        local warning_count=$(echo "$build_output" | grep -c "warning:" || true)

        BUILD_ERRORS[$plugin_name]="${error_count} errors"
        BUILD_WARNINGS[$plugin_name]="${warning_count} warnings"

        if [ "$VERBOSE" = true ]; then
            log_error "Build output for ${plugin_name}:"
            echo "$build_output" | tail -20
        fi

        return 1
    fi

    # Count warnings in successful build
    local warning_count=$(echo "$build_output" | grep -c "warning:" || true)
    BUILD_WARNINGS[$plugin_name]="${warning_count} warnings"
    BUILD_STATUS[$plugin_name]="SUCCESS"

    local build_end=$(date +%s)
    BUILD_TIME[$plugin_name]="$((build_end - build_start))s"

    log_success "${plugin_name} built successfully (${BUILD_TIME[$plugin_name]})"
}

check_plugin_cmakelists() {
    local plugin_dir="$1"
    local plugin_name="$2"

    if [ ! -f "${JUCE_BACKEND_DIR}/${plugin_dir}/CMakeLists.txt" ]; then
        BUILD_STATUS[$plugin_name]="MISSING"
        BUILD_ERRORS[$plugin_name]="CMakeLists.txt not found"
        return 1
    fi

    return 0
}

################################################################################
# Build Scoring
################################################################################

calculate_build_score() {
    local total_plugins=${#PLUGINS[@]}
    local success_count=0
    local total_warnings=0

    for plugin_name in "${PLUGINS[@]}"; do
        if [ "${BUILD_STATUS[$plugin_name]}" = "SUCCESS" ]; then
            ((success_count++))
        fi

        # Extract warning count
        local warnings="${BUILD_WARNINGS[$plugin_name]:-0 warnings}"
        warnings=${warnings// warnings/}
        total_warnings=$((total_warnings + warnings))
    done

    # Calculate base score (0-100)
    local base_score=$((success_count * 100 / total_plugins))

    # Deduct points for warnings (1 point per warning, max 20 points)
    local warning_penalty=$((total_warnings > 20 ? 20 : total_warnings))
    local final_score=$((base_score - warning_penalty))

    # Ensure score is between 0 and 100
    if [ $final_score -lt 0 ]; then
        final_score=0
    fi

    echo "$final_score"
}

get_score_grade() {
    local score=$1

    if [ $score -eq 100 ]; then
        echo "A+ (Perfect)"
    elif [ $score -ge 90 ]; then
        echo "A (Excellent)"
    elif [ $score -ge 80 ]; then
        echo "B (Good)"
    elif [ $score -ge 70 ]; then
        echo "C (Fair)"
    elif [ $score -ge 60 ]; then
        echo "D (Poor)"
    else
        echo "F (Failing)"
    fi
}

################################################################################
# Output Functions
################################################################################

print_text_results() {
    local score=$1
    local grade=$(get_score_grade $score)

    echo ""
    echo "=========================================="
    echo "  Build Health Score: ${score}% (${grade})"
    echo "=========================================="
    echo ""

    # Print plugin status
    printf "%-35s %-10s %-15s %-10s\n" "Plugin" "Status" "Issues" "Time"
    printf "%-35s %-10s %-15s %-10s\n" "-------" "------" "------" "----"

    for plugin_dir in "${!PLUGINS[@]}"; do
        local plugin_name="${PLUGINS[$plugin_dir]}"
        local status="${BUILD_STATUS[$plugin_name]:-UNKNOWN}"
        local issues=""
        local time="${BUILD_TIME[$plugin_name]:-N/A}"

        if [ "$status" = "SUCCESS" ]; then
            issues="${BUILD_WARNINGS[$plugin_name]:-0 warnings}"
        else
            issues="${BUILD_ERRORS[$plugin_name]:-Unknown error}"
        fi

        # Color coding
        if [ "$status" = "SUCCESS" ]; then
            status="✓ ${status}"
        elif [ "$status" = "FAILED" ]; then
            status="✗ ${status}"
        elif [ "$status" = "MISSING" ]; then
            status="? ${status}"
        fi

        printf "%-35s %-10s %-15s %-10s\n" "$plugin_name" "$status" "$issues" "$time"
    done

    echo ""

    # Summary statistics
    local total=${#PLUGINS[@]}
    local success=0
    local failed=0
    local missing=0
    local total_warnings=0

    for plugin_name in "${PLUGINS[@]}"; do
        local status="${BUILD_STATUS[$plugin_name]:-UNKNOWN}"

        case $status in
            SUCCESS)
                ((success++))
                ;;
            FAILED)
                ((failed++))
                ;;
            MISSING)
                ((missing++))
                ;;
        esac

        local warnings="${BUILD_WARNINGS[$plugin_name]:-0 warnings}"
        warnings=${warnings// warnings/}
        total_warnings=$((total_warnings + warnings))
    done

    echo "Summary:"
    echo "  Total Plugins:   ${total}"
    echo "  Successful:      ${success}"
    echo "  Failed:          ${failed}"
    echo "  Missing:         ${missing}"
    echo "  Total Warnings:  ${total_warnings}"
    echo ""

    # Recommendations
    if [ $score -lt 100 ]; then
        echo "Recommendations:"
        if [ $failed -gt 0 ]; then
            echo "  - Fix ${failed} failed plugin(s)"
        fi
        if [ $total_warnings -gt 0 ]; then
            echo "  - Resolve ${total_warnings} compiler warning(s)"
        fi
        if [ $missing -gt 0 ]; then
            echo "  - Add ${missing} missing plugin(s)"
        fi
        echo ""
    fi
}

print_json_results() {
    local score=$1

    echo "{"
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"build_health_score\": ${score},"
    echo "  \"grade\": \"$(get_score_grade $score)\","
    echo "  \"plugins\": {"

    local first=true
    for plugin_dir in "${!PLUGINS[@]}"; do
        if [ "$first" = false ]; then
            echo ","
        fi
        first=false

        local plugin_name="${PLUGINS[$plugin_dir]}"
        local status="${BUILD_STATUS[$plugin_name]:-UNKNOWN}"

        echo -n "    \"${plugin_name}\": {"
        echo -n "\"status\": \"${status}\""

        if [ "$status" = "SUCCESS" ]; then
            echo -n ", \"warnings\": \"${BUILD_WARNINGS[$plugin_name]:-0}\""
            echo -n ", \"build_time\": \"${BUILD_TIME[$plugin_name]:-N/A}\""
        elif [ "$status" = "FAILED" ]; then
            echo -n ", \"errors\": \"${BUILD_ERRORS[$plugin_name]:-Unknown error}\""
        fi

        echo -n "}"
    done

    echo ""
    echo "  }"
    echo "}"
}

################################################################################
# Main Execution
################################################################################

main() {
    parse_arguments "$@"
    print_header

    # Create build directory
    mkdir -p "${BUILD_DIR}"

    # Check and build each plugin
    for plugin_dir in "${!PLUGINS[@]}"; do
        local plugin_name="${PLUGINS[$plugin_dir]}"

        # Check if CMakeLists.txt exists
        if ! check_plugin_cmakelists "$plugin_dir" "$plugin_name"; then
            continue
        fi

        # Build the plugin
        build_plugin "$plugin_dir" "$plugin_name"
    done

    # Calculate build score
    local score=$(calculate_build_score)

    # Print results
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        print_json_results "$score"
    else
        print_text_results "$score"
    fi

    # Exit with appropriate code
    if [ $score -eq 100 ]; then
        exit 0
    elif [ $score -ge 70 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
