#!/bin/bash

###############################################################################
# Schedule Stakeholder Reports
#
# This script manages periodic report generation and distribution to stakeholders.
# It supports daily, weekly, and monthly reporting schedules with configurable
# recipient lists and notification preferences.
#
# Usage: ./schedule-stakeholder-report.sh [options]
#
# Options:
#   --frequency FREQ      Report frequency (daily, weekly, monthly) [default: weekly]
#   --day DAY             Day of week for weekly reports (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
#   --time TIME           Time of day to send report (HH:MM format) [default: 09:00]
#   --recipients FILE     Path to recipients configuration file
#   --dry-run             Show what would be done without sending
#   --force               Send report immediately regardless of schedule
#   --setup               Set up scheduled task (cron job)
#   --remove              Remove scheduled task
#   --list                List scheduled reports
#   --help                Show this help message
#
# Examples:
#   # Send weekly report every Friday at 9 AM
#   ./schedule-stakeholder-report.sh --frequency weekly --day Fri --time 09:00 --setup
#
#   # Send daily report immediately
#   ./schedule-stakeholder-report.sh --frequency daily --force
#
#   # List scheduled reports
#   ./schedule-stakeholder-report.sh --list
#
###############################################################################

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
REPORTS_DIR="${PROJECT_ROOT}/.beads/reports"
SCHEDULES_DIR="${REPORTS_DIR}/schedules"
STATE_FILE="${REPORTS_DIR}/report_state.json"

# Default values
FREQUENCY="weekly"
DAY="Fri"
TIME="09:00"
RECIPIENTS_FILE=""
DRY_RUN=false
FORCE=false
SETUP=false
REMOVE=false
LIST=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_dry_run() {
    echo -e "${YELLOW}[DRY-RUN]${NC} $*"
}

show_help() {
    grep '^#' "${BASH_SOURCE[0]}" | grep -v 'sed' | cut -c4- | sed 's/^//' | sed 's/^#//'
    exit 0
}

create_directories() {
    mkdir -p "$REPORTS_DIR"
    mkdir -p "$SCHEDULES_DIR"
    log_verbose "Created necessary directories"
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[VERBOSE]${NC} $*"
    fi
}

VERBOSE=false
if echo "$@" | grep -q -- --verbose; then
    VERBOSE=true
fi

###############################################################################
# State Management
###############################################################################

load_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "{}"
    fi
}

save_state() {
    local state=$1
    echo "$state" | jq '.' > "$STATE_FILE"
    log_verbose "State saved to: $STATE_FILE"
}

get_last_run() {
    local frequency=$1
    local state=$(load_state)

    echo "$state" | jq -r ".lastRuns.${frequency} // empty"
}

update_last_run() {
    local frequency=$1
    local state=$(load_state)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo "$state" | jq --arg freq "$frequency" --arg time "$timestamp" \
        '.lastRuns[$freq] = $time' | save_state -

    log_verbose "Updated last run for $frequency: $timestamp"
}

should_send_report() {
    local frequency=$1

    case "$frequency" in
        daily)
            # Check if run today
            local last_run=$(get_last_run "daily")
            if [ -z "$last_run" ]; then
                return 0
            fi

            local last_date=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_run" +"%Y-%m-%d" 2>/dev/null || echo "")
            local today=$(date +"%Y-%m-%d")

            if [ "$last_date" != "$today" ]; then
                return 0
            fi
            return 1
            ;;
        weekly)
            # Check if run this week
            local last_run=$(get_last_run "weekly")
            if [ -z "$last_run" ]; then
                return 0
            fi

            local last_week=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_run" +"%Y-%V" 2>/dev/null || echo "")
            local this_week=$(date +"%Y-%V")

            if [ "$last_week" != "$this_week" ]; then
                return 0
            fi
            return 1
            ;;
        monthly)
            # Check if run this month
            local last_run=$(get_last_run "monthly")
            if [ -z "$last_run" ]; then
                return 0
            fi

            local last_month=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_run" +"%Y-%m" 2>/dev/null || echo "")
            local this_month=$(date +"%Y-%m")

            if [ "$last_month" != "$this_month" ]; then
                return 0
            fi
            return 1
            ;;
        *)
            log_error "Unknown frequency: $frequency"
            return 1
            ;;
    esac
}

###############################################################################
# Recipients Management
###############################################################################

load_recipients() {
    local recipients_file="${1:-${PROJECT_ROOT}/.beads/stakeholders.json}"

    if [ ! -f "$recipients_file" ]; then
        log_warning "Recipients file not found: $recipients_file"
        # Create default recipients file
        cat > "$recipients_file" << 'EOF'
[
  {
    "id": "exec-1",
    "name": "Engineering Manager",
    "email": "eng-manager@example.com",
    "slackHandle": "@eng-manager",
    "roles": ["engineeringManager"],
    "preferences": {
      "emailEnabled": true,
      "slackEnabled": true,
      "frequency": "weekly",
      "topics": ["buildFailures", "qualityGates", "releaseReadiness"],
      "quietHoursStart": "18:00",
      "quietHoursEnd": "08:00"
    }
  },
  {
    "id": "dev-1",
    "name": "Lead Developer",
    "email": "lead-dev@example.com",
    "slackHandle": "@lead-dev",
    "roles": ["developer"],
    "preferences": {
      "emailEnabled": true,
      "slackEnabled": false,
      "frequency": "daily",
      "topics": ["buildFailures", "flakyTests"],
      "quietHoursStart": null,
      "quietHoursEnd": null
    }
  }
]
EOF
        log_info "Created default recipients file: $recipients_file"
    fi

    cat "$recipients_file"
}

filter_recipients_by_frequency() {
    local frequency=$1
    local recipients=$2

    echo "$recipients" | jq --arg freq "$frequency" \
        '[.[] | select(.preferences.frequency == $freq or .preferences.frequency == "immediate")]'
}

filter_recipients_by_topic() {
    local topic=$1
    local recipients=$2

    echo "$recipients" | jq --arg topic "$topic" \
        '[.[] | select(.preferences.topics[]? == $topic)]'
}

###############################################################################
# Report Generation
###############################################################################

generate_report() {
    local frequency=$1

    log_info "Generating $frequency report..."

    local days=30
    case "$frequency" in
        daily)
            days=1
            ;;
        weekly)
            days=7
            ;;
        monthly)
            days=30
            ;;
    esac

    # Call the report generation script
    local report_script="${SCRIPT_DIR}/generate-executive-report.sh"

    if [ ! -f "$report_script" ]; then
        log_error "Report generation script not found: $report_script"
        return 1
    fi

    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local output_file="${REPORTS_DIR}/stakeholder_report_${frequency}_${timestamp}.pdf"

    if [ "$DRY_RUN" = true ]; then
        log_dry_run "Would generate report: $output_file"
        echo "$output_file"
        return 0
    fi

    if "$report_script" --format pdf --days "$days" --output "$output_file" --quiet; then
        log_success "Report generated: $output_file"
        echo "$output_file"
        return 0
    else
        log_error "Failed to generate report"
        return 1
    fi
}

###############################################################################
# Notification Sending
###############################################################################

send_notifications() {
    local report_file=$1
    local recipients=$2

    log_info "Sending notifications to $(echo "$recipients" | jq 'length') recipients..."

    if [ "$DRY_RUN" = true ]; then
        echo "$recipients" | jq -r '.[] | "\(.name) <\(.email)>"' | while read -r recipient; do
            log_dry_run "Would send report to: $recipient"
        done
        return 0
    fi

    # Check for quiet hours
    local current_hour=$(date +"%H")
    local current_time=$(date +"%H:%M")

    echo "$recipients" | jq -c '.[]' | while read -r recipient; do
        local name=$(echo "$recipient" | jq -r '.name')
        local email=$(echo "$recipient" | jq -r '.email')
        local slack=$(echo "$recipient" | jq -r '.slackHandle // empty')
        local quiet_start=$(echo "$recipient" | jq -r '.preferences.quietHoursStart // empty')
        local quiet_end=$(echo "$recipient" | jq -r '.preferences.quietHoursEnd // empty')

        # Check quiet hours
        if [ -n "$quiet_start" ] && [ -n "$quiet_end" ]; then
            if [[ "$current_time" > "$quiet_start" ]] || [[ "$current_time" < "$quiet_end" ]]; then
                log_verbose "Skipping $name - in quiet hours ($quiet_start - $quiet_end)"
                continue
            fi
        fi

        # Send email
        if [ "$(echo "$recipient" | jq -r '.preferences.emailEnabled')" = "true" ] && [ -n "$email" ]; then
            log_info "Sending email to: $name <$email>"

            # In production, this would use actual email sending
            # For now, log the action
            log_verbose "Email sent to: $email with attachment: $report_file"
        fi

        # Send Slack notification
        if [ "$(echo "$recipient" | jq -r '.preferences.slackEnabled')" = "true" ] && [ -n "$slack" ]; then
            log_info "Sending Slack notification to: $slack"

            # In production, this would use Slack API
            # For now, log the action
            log_verbose "Slack notification sent to: $slack"
        fi
    done

    log_success "Notifications sent"
}

###############################################################################
# Schedule Management
###############################################################################

setup_schedule() {
    local frequency=$1
    local day=$2
    local time=$3

    log_info "Setting up $frequency report schedule..."

    # Validate cron time format
    if ! [[ "$time" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
        log_error "Invalid time format: $time (use HH:MM)"
        return 1
    fi

    local hour=$(echo "$time" | cut -d: -f1)
    local minute=$(echo "$time" | cut -d: -f2)

    # Build cron expression
    local cron_expr=""
    local dow=""

    case "$frequency" in
        daily)
            cron_expr="$minute $hour * * *"
            ;;
        weekly)
            # Convert day name to number (0=Sunday, 1=Monday, etc.)
            case "$day" in
                Mon|monday) dow="1" ;;
                Tue|tuesday) dow="2" ;;
                Wed|wednesday) dow="3" ;;
                Thu|thursday) dow="4" ;;
                Fri|friday) dow="5" ;;
                Sat|saturday) dow="6" ;;
                Sun|sunday) dow="0" ;;
                *)
                    log_error "Invalid day: $day"
                    return 1
                    ;;
            esac
            cron_expr="$minute $hour * * $dow"
            ;;
        monthly)
            cron_expr="$minute $hour 1 * *"
            ;;
        *)
            log_error "Unsupported frequency for scheduling: $frequency"
            return 1
            ;;
    esac

    # Create cron job
    local cron_cmd="cd $PROJECT_ROOT && $BASH_SOURCE --frequency $frequency --force > $REPORTS_DIR/scheduled_$frequency.log 2>&1"

    # Add to crontab
    local temp_cron="/tmp/cron_$$.txt"
    crontab -l > "$temp_cron" 2>/dev/null || true

    # Remove existing entry for this script
    grep -v "$BASH_SOURCE" "$temp_cron" > "${temp_cron}.new" 2>/dev/null || true
    mv "${temp_cron}.new" "$temp_cron"

    # Add new entry
    echo "$cron_expr $cron_cmd" >> "$temp_cron"

    # Install crontab
    crontab "$temp_cron"
    rm -f "$temp_cron"

    log_success "Scheduled $frequency report"
    log_info "Schedule: $cron_expr"
    log_info "Next run: $(cron_expr "$cron_expr" | head -n 1)"
}

remove_schedule() {
    log_info "Removing scheduled reports..."

    local temp_cron="/tmp/cron_$$.txt"
    crontab -l > "$temp_cron" 2>/dev/null || true

    # Remove all entries for this script
    grep -v "$BASH_SOURCE" "$temp_cron" > "${temp_cron}.new" 2>/dev/null || echo "" > "${temp_cron}.new"

    # Install new crontab
    crontab "${temp_cron}.new" 2>/dev/null || true
    rm -f "$temp_cron" "${temp_cron}.new"

    log_success "Scheduled reports removed"
}

list_schedules() {
    log_info "Scheduled reports:"

    crontab -l 2>/dev/null | grep "$BASH_SOURCE" || echo "No scheduled reports found"
}

###############################################################################
# Main Execution
###############################################################################

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --frequency)
                FREQUENCY="$2"
                shift 2
                ;;
            --day)
                DAY="$2"
                shift 2
                ;;
            --time)
                TIME="$2"
                shift 2
                ;;
            --recipients)
                RECIPIENTS_FILE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --setup)
                SETUP=true
                shift
                ;;
            --remove)
                REMOVE=true
                shift
                ;;
            --list)
                LIST=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                ;;
        esac
    done

    # Create necessary directories
    create_directories

    # Handle list command
    if [ "$LIST" = true ]; then
        list_schedules
        exit 0
    fi

    # Handle remove command
    if [ "$REMOVE" = true ]; then
        remove_schedule
        exit 0
    fi

    # Handle setup command
    if [ "$SETUP" = true ]; then
        setup_schedule "$FREQUENCY" "$DAY" "$TIME"
        exit 0
    fi

    # Check if we should send the report
    if [ "$FORCE" = false ] && ! should_send_report "$FREQUENCY"; then
        log_info "Report already sent for this $FREQUENCY period"
        log_info "Use --force to send anyway"
        exit 0
    fi

    # Load recipients
    local recipients=$(load_recipients "$RECIPIENTS_FILE")

    # Filter by frequency
    local filtered_recipients=$(filter_recipients_by_frequency "$FREQUENCY" "$recipients")

    local recipient_count=$(echo "$filtered_recipients" | jq 'length')
    if [ "$recipient_count" -eq 0 ]; then
        log_warning "No recipients found for frequency: $FREQUENCY"
        exit 0
    fi

    log_info "Found $recipient_count recipient(s) for $FREQUENCY reports"

    # Generate report
    local report_file=$(generate_report "$FREQUENCY")
    if [ $? -ne 0 ]; then
        log_error "Failed to generate report"
        exit 1
    fi

    # Send notifications
    send_notifications "$report_file" "$filtered_recipients"

    # Update state
    update_last_run "$FREQUENCY"

    log_success "Stakeholder report complete"
}

# Run main function
main "$@"
