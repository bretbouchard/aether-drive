#!/bin/bash

###############################################################################
# Automated Canary Release Script
#
# This script automates canary releases with gradual traffic shifting,
# real-time monitoring, automated rollback on failure, and promotion to full
# traffic when success criteria are met.
#
# Usage:
#   ./canary-release.sh --version <version> --baseline <baseline> [options]
#
# Options:
#   --version <version>         Version to deploy (required)
#   --baseline <baseline>       Baseline version to compare against (required)
#   --initial-traffic <pct>     Initial traffic percentage (default: 1)
#   --auto-promote              Automatically promote to 100% on success
#   --auto-rollback             Automatically rollback on failure
#   --dry-run                   Run without making changes
#   --help                      Show this help message
#
# Example:
#   ./canary-release.sh --version 2.0.0 --baseline 1.9.0 --initial-traffic 5
#
###############################################################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../../../.." && pwd)"

# Configuration
DEFAULT_INITIAL_TRAFFIC=1
DEFAULT_MONITORING_INTERVAL=60
DEFAULT_PROMOTION_DELAY=300
TRAFFIC_STEPS=(1 5 10 25 50 75 100)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# State variables
CANARY_VERSION=""
BASELINE_VERSION=""
INITIAL_TRAFFIC=$DEFAULT_INITIAL_TRAFFIC
AUTO_PROMOTE=false
AUTO_ROLLBACK=true
DRY_RUN=false

# Metrics storage
METRICS_FILE="/tmp/canary_metrics_$(date +%s).json"
STATE_FILE="/tmp/canary_state_$(date +%s).json"

###############################################################################
# Helper Functions
###############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

show_help() {
    sed -n '/^###/,/^###/p' "$0" | sed '1d;$d' | sed 's/^#//'
}

usage() {
    show_help
    exit 0
}

###############################################################################
# Argument Parsing
###############################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                CANARY_VERSION="$2"
                shift 2
                ;;
            --baseline)
                BASELINE_VERSION="$2"
                shift 2
                ;;
            --initial-traffic)
                INITIAL_TRAFFIC="$2"
                shift 2
                ;;
            --auto-promote)
                AUTO_PROMOTE=true
                shift
                ;;
            --auto-rollback)
                AUTO_ROLLBACK=true
                shift
                ;;
            --no-auto-rollback)
                AUTO_ROLLBACK=false
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$CANARY_VERSION" ]]; then
        log_error "Missing required argument: --version"
        usage
    fi

    if [[ -z "$BASELINE_VERSION" ]]; then
        log_error "Missing required argument: --baseline"
        usage
    fi

    # Validate traffic percentage
    if ! [[ "$INITIAL_TRAFFIC" =~ ^[0-9]+$ ]] || \
       [[ "$INITIAL_TRAFFIC" -lt 0 ]] || \
       [[ "$INITIAL_TRAFFIC" -gt 100 ]]; then
        log_error "Initial traffic must be between 0 and 100"
        exit 1
    fi
}

###############################################################################
# Validation Functions
###############################################################################

validate_preconditions() {
    log_info "Validating preconditions..."

    # Check if baseline version exists
    if ! check_version_exists "$BASELINE_VERSION"; then
        log_error "Baseline version $BASELINE_VERSION does not exist"
        exit 1
    fi

    # Check if canary version is built
    if ! check_version_built "$CANARY_VERSION"; then
        log_error "Canary version $CANARY_VERSION is not built"
        exit 1
    }

    # Check if there's already an active canary
    if check_active_canary; then
        log_error "An active canary release already exists"
        exit 1
    fi

    # Check load balancer availability
    if ! check_load_balancer; then
        log_error "Load balancer is not available"
        exit 1
    fi

    # Check monitoring system
    if ! check_monitoring_system; then
        log_error "Monitoring system is not available"
        exit 1
    fi

    log_success "Preconditions validated"
}

check_version_exists() {
    local version=$1
    # In production, check deployment registry
    return 0
}

check_version_built() {
    local version=$1
    # In production, check build artifacts
    return 0
}

check_active_canary() {
    # In production, check active canary releases
    return 1
}

check_load_balancer() {
    # In production, check load balancer health
    return 0
}

check_monitoring_system() {
    # In production, check monitoring system
    return 0
}

###############################################################################
# Deployment Functions
###############################################################################

deploy_canary() {
    log_info "Deploying canary version $CANARY_VERSION..."

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN: Would deploy $CANARY_VERSION"
        return 0
    fi

    # Deploy canary to production
    if ! deploy_version "$CANARY_VERSION" "production"; then
        log_error "Failed to deploy canary version"
        exit 1
    fi

    # Run smoke tests
    if ! run_smoke_tests "$CANARY_VERSION"; then
        log_error "Smoke tests failed"
        exit 1
    fi

    log_success "Canary version deployed successfully"
}

deploy_version() {
    local version=$1
    local environment=$2

    log_info "Deploying $version to $environment..."

    # In production, execute actual deployment
    # For now, simulate deployment
    sleep 2

    return 0
}

run_smoke_tests() {
    local version=$1

    log_info "Running smoke tests for $version..."

    # In production, execute actual smoke tests
    # For now, simulate tests
    sleep 5

    return 0
}

###############################################################################
# Traffic Management
###############################################################################

set_initial_traffic() {
    log_info "Setting initial traffic to $INITIAL_TRAFFIC%..."

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN: Would set traffic to $INITIAL_TRAFFIC%"
        return 0
    fi

    # Update load balancer configuration
    if ! update_traffic_split "$CANARY_VERSION" "$BASELINE_VERSION" "$INITIAL_TRAFFIC"; then
        log_error "Failed to set initial traffic"
        exit 1
    fi

    log_success "Initial traffic set to $INITIAL_TRAFFIC%"

    # Save state
    save_state
}

update_traffic_split() {
    local canary=$1
    local baseline=$2
    local canary_percentage=$3
    local baseline_percentage=$((100 - canary_percentage))

    log_info "Traffic split: $canary=$canary_percentage%, $baseline=$baseline_percentage%"

    # In production, update load balancer
    # For now, simulate update
    sleep 2

    return 0
}

increase_traffic() {
    local new_percentage=$1

    log_info "Increasing canary traffic to $new_percentage%..."

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN: Would increase traffic to $new_percentage%"
        return 0
    fi

    if ! update_traffic_split "$CANARY_VERSION" "$BASELINE_VERSION" "$new_percentage"; then
        log_error "Failed to increase traffic"
        return 1
    fi

    log_success "Traffic increased to $new_percentage%"

    # Save state
    save_state

    return 0
}

###############################################################################
# Monitoring Functions
###############################################################################

monitor_canary() {
    log_info "Starting canary monitoring..."
    log_info "Monitoring interval: ${DEFAULT_MONITORING_INTERVAL}s"

    local current_traffic=$INITIAL_TRAFFIC
    local step_index=0

    # Find starting step
    for i in "${!TRAFFIC_STEPS[@]}"; do
        if [[ "${TRAFFIC_STEPS[$i]}" -ge "$current_traffic" ]]; then
            step_index=$i
            break
        fi
    done

    while [[ $step_index -lt ${#TRAFFIC_STEPS[@]} ]]; do
        local target_traffic=${TRAFFIC_STEPS[$step_index]}

        log_info "Current step: $((step_index + 1))/${#TRAFFIC_STEPS[@]} - Target traffic: ${target_traffic}%"

        # Wait for monitoring period
        log_info "Monitoring for ${DEFAULT_MONITORING_INTERVAL}s..."
        sleep "$DEFAULT_MONITORING_INTERVAL"

        # Collect metrics
        if ! collect_metrics; then
            log_error "Failed to collect metrics"
            handle_failure "metrics_collection_failed"
            return 1
        fi

        # Evaluate metrics
        if ! evaluate_metrics; then
            log_error "Metrics evaluation failed"
            handle_failure "metrics_evaluation_failed"
            return 1
        fi

        # Check if we should advance
        if [[ "$current_traffic" -lt "$target_traffic" ]]; then
            if ! increase_traffic "$target_traffic"; then
                log_error "Failed to increase traffic"
                handle_failure "traffic_increase_failed"
                return 1
            fi
            current_traffic=$target_traffic
        fi

        # Check if this is the final step (100%)
        if [[ "$target_traffic" -eq 100 ]]; then
            log_success "Canary reached 100% traffic"
            finalize_canary
            return 0
        fi

        step_index=$((step_index + 1))
    done
}

collect_metrics() {
    log_info "Collecting metrics..."

    # Collect error rate
    local error_rate=$(get_error_rate)
    local baseline_error_rate=$(get_baseline_error_rate)

    # Collect latency
    local latency_p95=$(get_latency_p95)
    local baseline_latency_p95=$(get_baseline_latency_p95)

    # Collect resource usage
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)

    # Collect user feedback
    local positive_feedback=$(get_positive_feedback)
    local negative_feedback=$(get_negative_feedback)

    # Save metrics to JSON
    cat > "$METRICS_FILE" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "canary_version": "$CANARY_VERSION",
  "baseline_version": "$BASELINE_VERSION",
  "error_rate": $error_rate,
  "baseline_error_rate": $baseline_error_rate,
  "latency_p95": $latency_p95,
  "baseline_latency_p95": $baseline_latency_p95,
  "cpu_usage": $cpu_usage,
  "memory_usage": $memory_usage,
  "positive_feedback": $positive_feedback,
  "negative_feedback": $negative_feedback
}
EOF

    log_success "Metrics collected"

    return 0
}

get_error_rate() {
    # In production, query monitoring system
    echo "0.001"
}

get_baseline_error_rate() {
    # In production, query monitoring system
    echo "0.0008"
}

get_latency_p95() {
    # In production, query monitoring system
    echo "0.150"
}

get_baseline_latency_p95() {
    # In production, query monitoring system
    echo "0.140"
}

get_cpu_usage() {
    # In production, query monitoring system
    echo "45.0"
}

get_memory_usage() {
    # In production, query monitoring system
    echo "512"
}

get_positive_feedback() {
    # In production, query feedback system
    echo "95"
}

get_negative_feedback() {
    # In production, query feedback system
    echo "2"
}

evaluate_metrics() {
    log_info "Evaluating metrics..."

    # Read metrics from file
    local error_rate=$(jq -r '.error_rate' "$METRICS_FILE")
    local baseline_error_rate=$(jq -r '.baseline_error_rate' "$METRICS_FILE")
    local latency_p95=$(jq -r '.latency_p95' "$METRICS_FILE")
    local baseline_latency_p95=$(jq -r '.baseline_latency_p95' "$METRICS_FILE")
    local negative_feedback=$(jq -r '.negative_feedback' "$METRICS_FILE")

    # Calculate thresholds
    local error_rate_threshold=$(echo "$baseline_error_rate * 2.0" | bc -l)
    local latency_threshold=$(echo "$baseline_latency_p95 * 1.5" | bc -l)

    # Check error rate
    if (( $(echo "$error_rate > $error_rate_threshold" | bc -l) )); then
        log_error "Error rate $error_rate exceeds threshold $error_rate_threshold"
        return 1
    fi

    # Check latency
    if (( $(echo "$latency_p95 > $latency_threshold" | bc -l) )); then
        log_error "Latency $latency_p95 exceeds threshold $latency_threshold"
        return 1
    fi

    # Check user feedback
    if [[ "$negative_feedback" -gt 10 ]]; then
        log_error "Negative feedback $negative_feedback exceeds threshold"
        return 1
    fi

    log_success "Metrics evaluation passed"

    return 0
}

###############################################################################
# Rollback Functions
###############################################################################

handle_failure() {
    local reason=$1

    log_error "Canary failure detected: $reason"

    if [[ "$AUTO_ROLLBACK" == true ]]; then
        execute_rollback
    else
        log_warning "Auto-rollback disabled, manual intervention required"
        notify_manual_intervention "$reason"
    fi
}

execute_rollback() {
    log_warning "Executing rollback..."

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN: Would rollback to $BASELINE_VERSION"
        return 0
    fi

    # Immediately route all traffic to baseline
    if ! update_traffic_split "$CANARY_VERSION" "$BASELINE_VERSION" 0; then
        log_error "Failed to execute rollback"
        exit 1
    fi

    log_success "Rollback completed - all traffic on $BASELINE_VERSION"

    # Notify stakeholders
    notify_rollback

    # Cleanup canary
    cleanup_canary

    exit 1
}

notify_rollback() {
    log_info "Notifying stakeholders about rollback..."

    # In production, send notifications to Slack, email, PagerDuty
    # For now, just log
    log_warning "NOTIFICATION: Canary $CANARY_VERSION rolled back to $BASELINE_VERSION"
}

notify_manual_intervention() {
    local reason=$1

    log_warning "NOTIFICATION: Manual intervention required - $reason"
}

###############################################################################
# Finalization Functions
###############################################################################

finalize_canary() {
    log_success "Canary release completed successfully!"

    if [[ "$AUTO_PROMOTE" == true ]]; then
        log_info "Auto-promoting to full traffic..."
        promote_canary
    else
        log_info "Waiting ${DEFAULT_PROMOTION_DELAY}s before promotion..."
        sleep "$DEFAULT_PROMOTION_DELAY"
        promote_canary
    fi
}

promote_canary() {
    log_info "Promoting canary to full production..."

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN: Would promote $CANARY_VERSION to production"
        return 0
    fi

    # Ensure 100% traffic
    if ! update_traffic_split "$CANARY_VERSION" "$BASELINE_VERSION" 100; then
        log_error "Failed to promote canary"
        return 1
    fi

    # Update baseline version
    update_baseline_version

    # Notify stakeholders
    notify_promotion

    # Cleanup old baseline
    cleanup_baseline

    log_success "Canary $CANARY_VERSION promoted to production"
}

update_baseline_version() {
    log_info "Updating baseline version to $CANARY_VERSION..."

    # In production, update deployment registry
    sleep 1

    log_success "Baseline version updated"
}

notify_promotion() {
    log_info "Notifying stakeholders about promotion..."

    # In production, send notifications
    log_success "NOTIFICATION: Canary $CANARY_VERSION promoted to production"
}

cleanup_canary() {
    log_info "Cleaning up canary resources..."

    # In production, cleanup canary deployment
    sleep 1

    log_success "Canary cleanup completed"
}

cleanup_baseline() {
    log_info "Cleaning up old baseline resources..."

    # In production, cleanup old baseline deployment
    sleep 1

    log_success "Baseline cleanup completed"
}

###############################################################################
# State Management
###############################################################################

save_state() {
    cat > "$STATE_FILE" << EOF
{
  "canary_version": "$CANARY_VERSION",
  "baseline_version": "$BASELINE_VERSION",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "current_traffic": $(jq -r '.canary_percentage // 0' "$METRICS_FILE" 2>/dev/null || echo 0),
  "auto_promote": $AUTO_PROMOTE,
  "auto_rollback": $AUTO_ROLLBACK
}
EOF

    log_info "State saved to $STATE_FILE"
}

load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        log_info "Loading state from $STATE_FILE"
        source "$STATE_FILE"
    fi
}

###############################################################################
# Main Execution
###############################################################################

main() {
    log_info "=========================================="
    log_info "Canary Release Script"
    log_info "=========================================="
    log_info "Canary version: $CANARY_VERSION"
    log_info "Baseline version: $BASELINE_VERSION"
    log_info "Initial traffic: $INITIAL_TRAFFIC%"
    log_info "Auto-promote: $AUTO_PROMOTE"
    log_info "Auto-rollback: $AUTO_ROLLBACK"
    log_info "Dry run: $DRY_RUN"
    log_info "=========================================="

    # Parse arguments
    parse_arguments "$@"

    # Validate preconditions
    validate_preconditions

    # Deploy canary
    deploy_canary

    # Set initial traffic
    set_initial_traffic

    # Monitor canary
    monitor_canary

    # Cleanup
    rm -f "$METRICS_FILE" "$STATE_FILE"

    log_success "Canary release process completed successfully!"
}

# Trap signals
trap 'log_error "Script interrupted"; execute_rollback; exit 1' INT TERM

# Run main function
main "$@"
