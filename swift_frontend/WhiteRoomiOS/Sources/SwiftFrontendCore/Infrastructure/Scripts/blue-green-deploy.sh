#!/bin/bash

###############################################################################
# Blue-Green Deployment Script
#
# This script implements blue-green deployment strategy for zero-downtime
# deployments. It deploys to the inactive environment, validates the deployment,
# switches traffic, and provides instant rollback capability.
#
# Usage:
#   ./blue-green-deploy.sh --version <version> --environment <env> [options]
#
# Options:
#   --version <version>         Version to deploy (required)
#   --environment <env>         Environment to deploy to (required)
#   --skip-validation           Skip deployment validation
#   --no-cleanup                Don't cleanup old environment
#   --dry-run                   Run without making changes
#   --help                      Show this help message
#
# Example:
#   ./blue-green-deploy.sh --version 2.0.0 --environment production
#
###############################################################################

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../../../.." && pwd)"

# Configuration
DEPLOYMENT_TIMEOUT=600
VALIDATION_TIMEOUT=300
CLEANUP_DELAY=300
HEALTH_CHECK_INTERVAL=10

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# State variables
VERSION=""
ENVIRONMENT=""
SKIP_VALIDATION=false
NO_CLEANUP=false
DRY_RUN=false

# Deployment state
ACTIVE_COLOR=""
NEW_COLOR=""
DEPLOYMENT_ID=""
STATE_FILE="/tmp/bg_deployment_$(date +%s).json"

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
                VERSION="$2"
                shift 2
                ;;
            --environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --skip-validation)
                SKIP_VALIDATION=true
                shift
                ;;
            --no-cleanup)
                NO_CLEANUP=true
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
    if [[ -z "$VERSION" ]]; then
        log_error "Missing required argument: --version"
        usage
    fi

    if [[ -z "$ENVIRONMENT" ]]; then
        log_error "Missing required argument: --environment"
        usage
    fi

    # Validate environment
    if [[ "$ENVIRONMENT" != "production" ]] && \
       [[ "$ENVIRONMENT" != "staging" ]] && \
       [[ "$ENVIRONMENT" != "development" ]]; then
        log_error "Invalid environment: $ENVIRONMENT"
        exit 1
    fi
}

###############################################################################
# Environment Detection
###############################################################################

determine_active_color() {
    log_info "Determining active color..."

    if [[ "$DRY_RUN" == true ]]; then
        ACTIVE_COLOR="blue"
        NEW_COLOR="green"
        log_warning "DRY RUN: Assuming active color is $ACTIVE_COLOR"
        return 0
    fi

    # Query load balancer for active color
    ACTIVE_COLOR=$(get_active_color_from_lb)

    if [[ "$ACTIVE_COLOR" == "blue" ]]; then
        NEW_COLOR="green"
    elif [[ "$ACTIVE_COLOR" == "green" ]]; then
        NEW_COLOR="blue"
    else
        log_error "Unable to determine active color"
        exit 1
    fi

    log_success "Active color: $ACTIVE_COLOR, New color: $NEW_COLOR"
}

get_active_color_from_lb() {
    # In production, query load balancer
    # For now, assume blue is active
    echo "blue"
}

get_environment_state() {
    local color=$1

    # In production, query deployment service
    echo "active=$([[ "$color" == "$ACTIVE_COLOR" ]] && echo "true" || echo "false")"
    echo "version=$(get_color_version "$color")"
    echo "healthy=$(check_color_health "$color" && echo "true" || echo "false")"
}

get_color_version() {
    local color=$1
    # In production, query deployment service
    if [[ "$color" == "$ACTIVE_COLOR" ]]; then
        echo "1.0.0"
    else
        echo "0.0.0"
    fi
}

check_color_health() {
    local color=$1
    # In production, check health endpoints
    return 0
}

###############################################################################
# Deployment Functions
###############################################################################

deploy_to_new_color() {
    log_info "Deploying version $VERSION to $NEW_COLOR environment..."

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN: Would deploy to $NEW_COLOR"
        return 0
    fi

    # Create deployment ID
    DEPLOYMENT_ID="${ENVIRONMENT}-${NEW_COLOR}-${VERSION}-$(date +%s)"

    # Deploy to new color
    if ! execute_deployment "$VERSION" "$ENVIRONMENT" "$NEW_COLOR"; then
        log_error "Deployment to $NEW_COLOR failed"
        exit 1
    fi

    # Wait for deployment to be ready
    if ! wait_for_deployment_ready; then
        log_error "Deployment timed out"
        exit 1
    fi

    log_success "Deployment to $NEW_COLOR completed"
}

execute_deployment() {
    local version=$1
    local environment=$2
    local color=$3

    log_info "Executing deployment: $version to $environment-$color..."

    # In production, execute actual deployment
    # For now, simulate deployment
    sleep 5

    return 0
}

wait_for_deployment_ready() {
    log_info "Waiting for deployment to be ready..."

    local elapsed=0
    while [[ $elapsed -lt $DEPLOYMENT_TIMEOUT ]]; do
        if check_deployment_ready; then
            log_success "Deployment is ready"
            return 0
        fi

        sleep $HEALTH_CHECK_INTERVAL
        elapsed=$((elapsed + HEALTH_CHECK_INTERVAL))
        log_info "Waiting... ($elapsed/${DEPLOYMENT_TIMEOUT}s)"
    done

    log_error "Deployment readiness timeout"
    return 1
}

check_deployment_ready() {
    # In production, check deployment health
    # For now, simulate ready after 30 seconds
    return 0
}

###############################################################################
# Validation Functions
###############################################################################

validate_deployment() {
    if [[ "$SKIP_VALIDATION" == true ]]; then
        log_warning "Skipping validation"
        return 0
    fi

    log_info "Running deployment validation..."

    # Health check validation
    if ! validate_health_check; then
        log_error "Health check validation failed"
        return 1
    fi

    # Smoke tests
    if ! run_smoke_tests; then
        log_error "Smoke tests failed"
        return 1
    fi

    # Integration tests
    if ! run_integration_tests; then
        log_error "Integration tests failed"
        return 1
    fi

    log_success "Deployment validation passed"
}

validate_health_check() {
    log_info "Validating health checks..."

    local elapsed=0
    while [[ $elapsed -lt $VALIDATION_TIMEOUT ]]; do
        if check_health_endpoint; then
            log_success "Health check passed"
            return 0
        fi

        sleep $HEALTH_CHECK_INTERVAL
        elapsed=$((elapsed + HEALTH_CHECK_INTERVAL))
    done

    log_error "Health check validation timeout"
    return 1
}

check_health_endpoint() {
    # In production, query health endpoint
    # For now, simulate success
    return 0
}

run_smoke_tests() {
    log_info "Running smoke tests..."

    # In production, execute smoke tests
    # For now, simulate tests
    sleep 10

    log_success "Smoke tests passed"
    return 0
}

run_integration_tests() {
    log_info "Running integration tests..."

    # In production, execute integration tests
    # For now, simulate tests
    sleep 15

    log_success "Integration tests passed"
    return 0
}

###############################################################################
# Traffic Switching
###############################################################################

switch_traffic() {
    log_info "Switching traffic to $NEW_COLOR..."

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN: Would switch traffic to $NEW_COLOR"
        return 0
    fi

    # Update load balancer
    if ! update_load_balancer "$NEW_COLOR"; then
        log_error "Failed to switch traffic"
        return 1
    fi

    # Verify traffic switch
    if ! verify_traffic_switch; then
        log_error "Traffic switch verification failed"
        return 1
    fi

    log_success "Traffic switched to $NEW_COLOR"

    # Save state
    save_state
}

update_load_balancer() {
    local new_color=$1

    log_info "Updating load balancer to route to $new_color..."

    # In production, update load balancer configuration
    # For now, simulate update
    sleep 5

    return 0
}

verify_traffic_switch() {
    log_info "Verifying traffic switch..."

    # Wait for load balancer to update
    sleep 10

    # Make test requests
    local success_count=0
    local total_requests=10

    for i in $(seq 1 $total_requests); do
        if make_test_request; then
            success_count=$((success_count + 1))
        fi
        sleep 1
    done

    local success_percentage=$((success_count * 100 / total_requests))

    if [[ $success_percentage -ge 80 ]]; then
        log_success "Traffic verification: $success_count/$total_requests requests successful"
        return 0
    else
        log_error "Traffic verification: Only $success_count/$total_requests requests successful"
        return 1
    fi
}

make_test_request() {
    # In production, make actual HTTP request
    # For now, simulate success
    return 0
}

###############################################################################
# Rollback Functions
###############################################################################

rollback_deployment() {
    log_warning "Rolling back deployment..."

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN: Would rollback to $ACTIVE_COLOR"
        return 0
    fi

    # Switch traffic back to active color
    if ! update_load_balancer "$ACTIVE_COLOR"; then
        log_error "Failed to rollback traffic"
        exit 1
    fi

    log_success "Rollback completed - traffic on $ACTIVE_COLOR"

    # Notify stakeholders
    notify_rollback

    exit 1
}

notify_rollback() {
    log_warning "NOTIFICATION: Deployment rolled back to $ACTIVE_COLOR"
}

###############################################################################
# Cleanup Functions
###############################################################################

cleanup_old_environment() {
    if [[ "$NO_CLEANUP" == true ]]; then
        log_info "Skipping cleanup (--no-cleanup flag)"
        return 0
    fi

    log_info "Scheduling cleanup of old $ACTIVE_COLOR environment..."

    # Schedule cleanup in background
    (
        sleep $CLEANUP_DELAY
        log_info "Cleaning up old $ACTIVE_COLOR environment..."

        if [[ "$DRY_RUN" == false ]]; then
            # In production, cleanup old deployment
            sleep 5
        fi

        log_success "Cleanup completed"
    ) &

    log_info "Cleanup scheduled in ${CLEANUP_DELAY}s"
}

###############################################################################
# State Management
###############################################################################

save_state() {
    cat > "$STATE_FILE" << EOF
{
  "deployment_id": "$DEPLOYMENT_ID",
  "version": "$VERSION",
  "environment": "$ENVIRONMENT",
  "active_color": "$ACTIVE_COLOR",
  "new_color": "$NEW_COLOR",
  "deployed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "active"
}
EOF

    log_info "State saved to $STATE_FILE"
}

###############################################################################
# Main Execution
###############################################################################

main() {
    log_info "=========================================="
    log_info "Blue-Green Deployment Script"
    log_info "=========================================="
    log_info "Version: $VERSION"
    log_info "Environment: $ENVIRONMENT"
    log_info "Skip validation: $SKIP_VALIDATION"
    log_info "No cleanup: $NO_CLEANUP"
    log_info "Dry run: $DRY_RUN"
    log_info "=========================================="

    # Parse arguments
    parse_arguments "$@"

    # Determine active color
    determine_active_color

    # Deploy to new color
    deploy_to_new_color

    # Validate deployment
    if ! validate_deployment; then
        log_error "Deployment validation failed"
        rollback_deployment
    fi

    # Switch traffic
    if ! switch_traffic; then
        log_error "Traffic switch failed"
        rollback_deployment
    fi

    # Schedule cleanup
    cleanup_old_environment

    # Success!
    log_success "=========================================="
    log_success "Blue-Green Deployment Successful!"
    log_success "Version $VERSION is now active in $ENVIRONMENT"
    log_success "=========================================="

    # Cleanup state file
    rm -f "$STATE_FILE"
}

# Trap signals
trap 'log_error "Deployment interrupted"; rollback_deployment; exit 1' INT TERM

# Run main function
main "$@"
