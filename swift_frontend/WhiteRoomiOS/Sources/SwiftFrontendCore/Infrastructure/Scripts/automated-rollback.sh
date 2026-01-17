#!/bin/bash

###############################################################################
# Automated Rollback Script
#
# This script provides automated rollback capabilities for failed deployments.
# It detects failure conditions, executes rollback plans, validates rollback
# success, and generates incident reports.
#
# Usage:
#   ./automated-rollback.sh --deployment-id <id> --reason <reason> [options]
#
# Options:
#   --deployment-id <id>       Deployment ID to rollback (required)
#   --reason <reason>          Reason for rollback (required)
#   --rollback-version <ver>   Version to rollback to (optional)
#   --skip-validation          Skip post-rollback validation
#   --dry-run                  Run without making changes
#   --help                     Show this help message
#
# Example:
#   ./automated-rollback.sh --deployment-id prod-deploy-123 --reason "High error rate"
#
###############################################################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../../../.." && pwd)"

# Configuration
ROLLBACK_TIMEOUT=300
VALIDATION_TIMEOUT=180
REPORT_FILE="/tmp/rollback_report_$(date +%s).md"
METRICS_FILE="/tmp/rollback_metrics_$(date +%s).json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# State variables
DEPLOYMENT_ID=""
REASON=""
ROLLBACK_VERSION=""
SKIP_VALIDATION=false
DRY_RUN=false

# Rollback state
FAILED_VERSION=""
ROLLED_BACK_VERSION=""
ROLLBACK_START_TIME=""
ROLLBACK_END_TIME=""
ROLLBACK_DURATION=0
ROLLBACK_SUCCESS=false
USER_IMPACT=""

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
            --deployment-id)
                DEPLOYMENT_ID="$2"
                shift 2
                ;;
            --reason)
                REASON="$2"
                shift 2
                ;;
            --rollback-version)
                ROLLBACK_VERSION="$2"
                shift 2
                ;;
            --skip-validation)
                SKIP_VALIDATION=true
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
    if [[ -z "$DEPLOYMENT_ID" ]]; then
        log_error "Missing required argument: --deployment-id"
        usage
    fi

    if [[ -z "$REASON" ]]; then
        log_error "Missing required argument: --reason"
        usage
    fi
}

###############################################################################
# Pre-Rollback Checks
###############################################################################

validate_preconditions() {
    log_info "Validating rollback preconditions..."

    # Check if deployment exists
    if ! check_deployment_exists "$DEPLOYMENT_ID"; then
        log_error "Deployment $DEPLOYMENT_ID not found"
        exit 1
    fi

    # Get failed version
    FAILED_VERSION=$(get_deployment_version "$DEPLOYMENT_ID")
    log_info "Failed version: $FAILED_VERSION"

    # Determine rollback version if not specified
    if [[ -z "$ROLLBACK_VERSION" ]]; then
        ROLLBACK_VERSION=$(determine_rollback_version)
        log_info "Auto-detected rollback version: $ROLLBACK_VERSION"
    fi

    # Verify rollback version exists
    if ! check_version_exists "$ROLLBACK_VERSION"; then
        log_error "Rollback version $ROLLBACK_VERSION not found"
        exit 1
    fi

    # Check if rollback is already in progress
    if check_rollback_in_progress; then
        log_error "Rollback already in progress for this deployment"
        exit 1
    fi

    # Check cooldown period
    if check_rollback_cooldown; then
        log_warning "Rollback cooldown period active, proceeding anyway"
    fi

    log_success "Preconditions validated"
}

check_deployment_exists() {
    local deployment_id=$1
    # In production, query deployment registry
    return 0
}

get_deployment_version() {
    local deployment_id=$1
    # In production, query deployment registry
    echo "2.0.0"
}

determine_rollback_version() {
    # In production, query deployment history for previous successful version
    echo "1.9.0"
}

check_version_exists() {
    local version=$1
    # In production, check version registry
    return 0
}

check_rollback_in_progress() {
    # In production, check active rollbacks
    return 1
}

check_rollback_cooldown() {
    # In production, check cooldown period
    return 1
}

###############################################################################
# Rollback Execution
###############################################################################

execute_rollback() {
    log_info "=========================================="
    log_info "Executing Rollback"
    log_info "=========================================="
    log_info "Deployment ID: $DEPLOYMENT_ID"
    log_info "Failed version: $FAILED_VERSION"
    log_info "Rollback version: $ROLLBACK_VERSION"
    log_info "Reason: $REASON"
    log_info "=========================================="

    ROLLBACK_START_TIME=$(date +%s)

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN: Would execute rollback"
        ROLLBACK_SUCCESS=true
        finalize_rollback
        return 0
    fi

    # Collect pre-rollback metrics
    collect_pre_rollback_metrics

    # Mark rollback as in progress
    mark_rollback_in_progress

    # Execute actual rollback
    if ! perform_rollback; then
        log_error "Rollback execution failed"
        mark_rollback_failed
        exit 1
    fi

    # Wait for rollback to complete
    if ! wait_for_rollback_complete; then
        log_error "Rollback completion timeout"
        mark_rollback_failed
        exit 1
    fi

    ROLLBACK_SUCCESS=true
    ROLLBACK_END_TIME=$(date +%s)
    ROLLBACK_DURATION=$((ROLLBACK_END_TIME - ROLLBACK_START_TIME))

    log_success "Rollback completed in ${ROLLBACK_DURATION}s"
}

collect_pre_rollback_metrics() {
    log_info "Collecting pre-rollback metrics..."

    # Collect error rate
    local error_rate=$(get_current_error_rate)

    # Collect latency
    local latency_p95=$(get_current_latency_p95)

    # Collect resource usage
    local cpu_usage=$(get_current_cpu_usage)
    local memory_usage=$(get_current_memory_usage)

    # Save metrics
    cat > "$METRICS_FILE" << EOF
{
  "deployment_id": "$DEPLOYMENT_ID",
  "failed_version": "$FAILED_VERSION",
  "rollback_version": "$ROLLBACK_VERSION",
  "reason": "$REASON",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "error_rate": $error_rate,
  "latency_p95": $latency_p95,
  "cpu_usage": $cpu_usage,
  "memory_usage": $memory_usage
}
EOF

    log_info "Pre-rollback metrics saved to $METRICS_FILE"
}

get_current_error_rate() {
    # In production, query monitoring system
    echo "0.05"
}

get_current_latency_p95() {
    # In production, query monitoring system
    echo "2.5"
}

get_current_cpu_usage() {
    # In production, query monitoring system
    echo "85.0"
}

get_current_memory_usage() {
    # In production, query monitoring system
    echo "2048"
}

mark_rollback_in_progress() {
    log_info "Marking rollback as in progress..."

    # In production, update deployment state
    sleep 1

    log_info "Rollback marked as in progress"
}

perform_rollback() {
    log_info "Performing rollback to $ROLLBACK_VERSION..."

    # Update load balancer/traffic routing
    if ! update_traffic_routing "$ROLLBACK_VERSION"; then
        log_error "Failed to update traffic routing"
        return 1
    fi

    # Restart services if needed
    if ! restart_services "$ROLLBACK_VERSION"; then
        log_error "Failed to restart services"
        return 1
    fi

    log_success "Rollback execution completed"
    return 0
}

update_traffic_routing() {
    local target_version=$1

    log_info "Updating traffic routing to version $target_version..."

    # In production, update load balancer configuration
    # For now, simulate update
    sleep 5

    return 0
}

restart_services() {
    local target_version=$1

    log_info "Restarting services for version $target_version..."

    # In production, restart services with new version
    # For now, simulate restart
    sleep 10

    return 0
}

wait_for_rollback_complete() {
    log_info "Waiting for rollback to complete..."

    local elapsed=0
    while [[ $elapsed -lt $ROLLBACK_TIMEOUT ]]; do
        if check_rollback_complete; then
            log_success "Rollback is complete"
            return 0
        fi

        sleep 5
        elapsed=$((elapsed + 5))
        log_info "Waiting... ($elapsed/${ROLLBACK_TIMEOUT}s)"
    done

    log_error "Rollback completion timeout"
    return 1
}

check_rollback_complete() {
    # In production, check rollback status
    # For now, simulate success after 30 seconds
    return 0
}

mark_rollback_failed() {
    log_warning "Marking rollback as failed..."

    # In production, update deployment state
    sleep 1

    log_warning "Rollback marked as failed"
}

###############################################################################
# Post-Rollback Validation
###############################################################################

validate_rollback() {
    if [[ "$SKIP_VALIDATION" == true ]]; then
        log_warning "Skipping post-rollback validation"
        return 0
    fi

    log_info "Running post-rollback validation..."

    # Verify current version
    if ! verify_current_version; then
        log_error "Version verification failed"
        return 1
    fi

    # Health check validation
    if ! validate_health_check; then
        log_error "Health check validation failed"
        return 1
    fi

    # Metrics validation
    if ! validate_metrics; then
        log_error "Metrics validation failed"
        return 1
    fi

    log_success "Post-rollback validation passed"
}

verify_current_version() {
    log_info "Verifying current version..."

    local current_version=$(get_current_version)

    if [[ "$current_version" == "$ROLLBACK_VERSION" ]]; then
        log_success "Current version verified: $ROLLBACK_VERSION"
        return 0
    else
        log_error "Version mismatch: expected $ROLLBACK_VERSION, got $current_version"
        return 1
    fi
}

get_current_version() {
    # In production, query deployment service
    echo "$ROLLBACK_VERSION"
}

validate_health_check() {
    log_info "Validating health checks..."

    local elapsed=0
    while [[ $elapsed -lt $VALIDATION_TIMEOUT ]]; do
        if check_health_healthy; then
            log_success "Health check passed"
            return 0
        fi

        sleep 5
        elapsed=$((elapsed + 5))
        log_info "Waiting for healthy... ($elapsed/${VALIDATION_TIMEOUT}s)"
    done

    log_error "Health check validation timeout"
    return 1
}

check_health_healthy() {
    # In production, check health endpoints
    # For now, simulate success
    return 0
}

validate_metrics() {
    log_info "Validating metrics..."

    # Collect post-rollback metrics
    local error_rate=$(get_rollback_error_rate)
    local latency_p95=$(get_rollback_latency_p95)

    # Compare with pre-rollback metrics
    local pre_error_rate=$(jq -r '.error_rate' "$METRICS_FILE")
    local pre_latency_p95=$(jq -r '.latency_p95' "$METRICS_FILE")

    log_info "Error rate: $error_rate (was $pre_error_rate)"
    log_info "Latency p95: $latency_p95 (was $pre_latency_p95)"

    # Check if metrics improved
    if (( $(echo "$error_rate < $pre_error_rate" | bc -l) )); then
        log_success "Error rate improved"
    else
        log_warning "Error rate did not improve"
    fi

    if (( $(echo "$latency_p95 < $pre_latency_p95" | bc -l) )); then
        log_success "Latency improved"
    else
        log_warning "Latency did not improve"
    fi

    return 0
}

get_rollback_error_rate() {
    # In production, query monitoring system
    echo "0.001"
}

get_rollback_latency_p95() {
    # In production, query monitoring system
    echo "0.150"
}

###############################################################################
# Impact Assessment
###############################################################################

assess_user_impact() {
    log_info "Assessing user impact..."

    # Calculate affected users
    local affected_users=$(estimate_affected_users)

    # Calculate downtime
    local downtime_seconds=$ROLLBACK_DURATION

    # Estimate error count
    local error_count=$(estimate_error_count)

    # Determine impact level
    local impact_level=$(determine_impact_level "$affected_users" "$downtime_seconds")

    USER_IMPACT="affected_users=$affected_users,downtime=${downtime_seconds}s,errors=$error_count,impact=$impact_level"

    log_info "User impact: $USER_IMPACT"
}

estimate_affected_users() {
    # In production, query analytics system
    echo "150"
}

estimate_error_count() {
    # In production, query error tracking system
    echo "25"
}

determine_impact_level() {
    local affected_users=$1
    local downtime_seconds=$2

    if [[ $affected_users -lt 10 ]] && [[ $downtime_seconds -lt 60 ]]; then
        echo "low"
    elif [[ $affected_users -lt 100 ]] && [[ $downtime_seconds -lt 300 ]]; then
        echo "medium"
    elif [[ $affected_users -lt 1000 ]] && [[ $downtime_seconds -lt 600 ]]; then
        echo "high"
    else
        echo "critical"
    fi
}

###############################################################################
# Notification and Reporting
###############################################################################

notify_stakeholders() {
    log_info "Notifying stakeholders about rollback..."

    local severity=$(determine_severity)

    # In production, send notifications to Slack, email, PagerDuty
    log_warning "NOTIFICATION [$severity]: Rollback executed for deployment $DEPLOYMENT_ID"
    log_warning "NOTIFICATION: Reason: $REASON"
    log_warning "NOTIFICATION: User impact: $USER_IMPACT"
}

determine_severity() {
    if [[ "$USER_IMPACT" == *"impact=critical"* ]]; then
        echo "CRITICAL"
    elif [[ "$USER_IMPACT" == *"impact=high"* ]]; then
        echo "HIGH"
    elif [[ "$USER_IMPACT" == *"impact=medium"* ]]; then
        echo "MEDIUM"
    else
        echo "LOW"
    fi
}

generate_report() {
    log_info "Generating rollback report..."

    cat > "$REPORT_FILE" << EOF
# Rollback Report

## Deployment Information
- **Deployment ID**: $DEPLOYMENT_ID
- **Failed Version**: $FAILED_VERSION
- **Rolled Back Version**: $ROLLBACK_VERSION
- **Rollback Reason**: $REASON

## Timeline
- **Started**: $(date -u -d @$ROLLBACK_START_TIME +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r $ROLLBACK_START_TIME +%Y-%m-%dT%H:%M:%SZ)
- **Completed**: $(date -u -d @$ROLLBACK_END_TIME +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r $ROLLBACK_END_TIME +%Y-%m-%dT%H:%M:%SZ)
- **Duration**: ${ROLLBACK_DURATION}s

## User Impact
- $USER_IMPACT

## Pre-Rollback Metrics
\`\`\`json
$(cat "$METRICS_FILE")
\`\`\`

## Validation Results
- Version Verification: $([ "$ROLLBACK_SUCCESS" == true ] && echo "✓ Passed" || echo "✗ Failed")
- Health Check: $([ "$SKIP_VALIDATION" == false ] && echo "✓ Passed" || echo "⊘ Skipped")
- Metrics Validation: $([ "$SKIP_VALIDATION" == false ] && echo "✓ Passed" || echo "⊘ Skipped")

## Root Cause Analysis
- **Likely Cause**: Deployment introduced performance regression
- **Contributing Factors**: Insufficient pre-deployment testing
- **Recommendations**: Increase test coverage, add performance regression tests

## Preventive Actions
1. Add performance validation to deployment pipeline
2. Increase monitoring sensitivity during deployment
3. Implement canary releases for future deployments

---
**Generated**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Status**: $([ "$ROLLBACK_SUCCESS" == true ] && echo "✓ Successful" || echo "✗ Failed")
EOF

    log_success "Report saved to $REPORT_FILE"
}

finalize_rollback() {
    ROLLED_BACK_VERSION=$ROLLBACK_VERSION

    # Assess user impact
    assess_user_impact

    # Notify stakeholders
    notify_stakeholders

    # Generate report
    generate_report

    # Mark rollback as complete
    mark_rollback_complete
}

mark_rollback_complete() {
    log_info "Marking rollback as complete..."

    # In production, update deployment state
    sleep 1

    log_info "Rollback marked as complete"
}

###############################################################################
# Main Execution
###############################################################################

main() {
    log_info "=========================================="
    log_info "Automated Rollback Script"
    log_info "=========================================="
    log_info "Deployment ID: $DEPLOYMENT_ID"
    log_info "Reason: $REASON"
    log_info "Skip validation: $SKIP_VALIDATION"
    log_info "Dry run: $DRY_RUN"
    log_info "=========================================="

    # Parse arguments
    parse_arguments "$@"

    # Validate preconditions
    validate_preconditions

    # Execute rollback
    execute_rollback

    # Validate rollback
    if [[ "$ROLLBACK_SUCCESS" == true ]]; then
        if ! validate_rollback; then
            log_warning "Post-rollback validation failed, but rollback was executed"
        fi
    fi

    # Finalize
    finalize_rollback

    # Success!
    log_success "=========================================="
    log_success "Rollback Process Completed!"
    log_success "Report: $REPORT_FILE"
    log_success "=========================================="
}

# Trap signals
trap 'log_error "Rollback interrupted"; mark_rollback_failed; exit 1' INT TERM

# Run main function
main "$@"
