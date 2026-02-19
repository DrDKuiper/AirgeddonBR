#!/usr/bin/env bash

################################################################################
# Airgeddon Integration Example
# Demonstrates how to use the new improvement modules
# Version: 1.0
################################################################################

# Set script options
set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import modules
source "${SCRIPT_DIR}/core/logging.sh"
source "${SCRIPT_DIR}/tools/report_generator.sh"
source "${SCRIPT_DIR}/tools/vulnerability_analyzer.sh"

###############################################################################
# Display welcome message
###############################################################################
display_welcome() {
    clear
    cat <<EOF
${BLUE}╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║         🔒 AIRGEDDON SECURITY ANALYSIS DEMO 🔒               ║
║                                                               ║
║  Integrated Security Analysis & Reporting System             ║
║  Version 1.0                                                 ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝${NC}
EOF
}

###############################################################################
# Demonstrate logging system
###############################################################################
demo_logging() {
    log_info "═══════════════════════════════════════════════════════════"
    log_info "DEMO 1: Logging System"
    log_info "═══════════════════════════════════════════════════════════"
    
    log_debug "This is a debug message"
    log_info "This is an info message"
    log_warn "This is a warning message"
    log_error "This is an error message (will appear in error log)"
    log_critical "This is a critical message"
}

###############################################################################
# Demonstrate vulnerability analysis
###############################################################################
demo_vulnerability_analysis() {
    log_info ""
    log_info "═══════════════════════════════════════════════════════════"
    log_info "DEMO 2: Vulnerability Analysis"
    log_info "═══════════════════════════════════════════════════════════"
    
    # Create sample networks
    declare -a networks=(
        '{"bssid":"AA:BB:CC:DD:EE:01","essid":"OpenNetwork","encryption":"Open","signal_strength":-45,"channel":6}'
        '{"bssid":"AA:BB:CC:DD:EE:02","essid":"LegacyWEP","encryption":"WEP","signal_strength":-60,"channel":11}'
        '{"bssid":"AA:BB:CC:DD:EE:03","essid":"SecureNetwork","encryption":"WPA3","signal_strength":-50,"channel":1}'
        '{"bssid":"88:51:FB:AA:BB:CC","essid":"VulnerableTP-Link","encryption":"WPA2","signal_strength":-40,"channel":6}'
    )
    
    # Sample WordPress with WEP
    initialize_report "WiFi Security Audit - February 19, 2025"
    
    for network in "${networks[@]}"; do
        # Extract values from JSON
        local bssid=$(echo "${network}" | grep -o '"bssid":"[^"]*"' | cut -d'"' -f4)
        local essid=$(echo "${network}" | grep -o '"essid":"[^"]*"' | cut -d'"' -f4)
        local encryption=$(echo "${network}" | grep -o '"encryption":"[^"]*"' | cut -d'"' -f4)
        local signal=$(echo "${network}" | grep -o '"signal_strength":-?[0-9]*' | cut -d':' -f2)
        local channel=$(echo "${network}" | grep -o '"channel":[0-9]*' | cut -d':' -f2)
        
        log_info "Analyzing: ${essid} (${bssid})"
        
        # Perform analysis
        perform_security_analysis "${bssid}" "${essid}" "${encryption}" "${signal}"
        
        # Calculate risk score
        local risk=$(calculate_risk_score "${bssid}" "${encryption}" "${signal}" "no" "no")
        log_info "Risk Score: ${risk}/100"
        
        # Check vulnerabilities
        local vulns=$(check_common_vulnerabilities "${network}")
        if [[ "${vulns}" != "NONE" ]]; then
            log_warn "Vulnerabilities: ${vulns}"
            add_vulnerability "${bssid}" "${vulns}" "HIGH" "Network has identified vulnerabilities" "Improve security configuration"
        fi
        
        # Add to report
        add_network_to_report "${bssid}" "${essid}" "${encryption}" "${signal}" "${channel}"
        
        echo ""
    done
}

###############################################################################
# Demonstrate report generation
###############################################################################
demo_report_generation() {
    log_info "═══════════════════════════════════════════════════════════"
    log_info "DEMO 3: Report Generation"
    log_info "═══════════════════════════════════════════════════════════"
    
    # Generate reports
    local output_dir="/tmp/airgeddon_reports"
    mkdir -p "${output_dir}"
    
    log_info "Generating reports in: ${output_dir}"
    
    # JSON Report
    generate_json_report "${output_dir}/report.json"
    log_info "JSON report: ${output_dir}/report.json"
    
    # HTML Report
    generate_html_report "${output_dir}/report.html"
    log_info "HTML report: ${output_dir}/report.html"
    
    # CSV Report
    generate_csv_report "${output_dir}/networks.csv"
    log_info "CSV report: ${output_dir}/networks.csv"
    
    # Display report summary
    echo ""
    display_report_summary
}

###############################################################################
# Demonstrate log management
###############################################################################
demo_log_management() {
    log_info ""
    log_info "═══════════════════════════════════════════════════════════"
    log_info "DEMO 4: Log Management"
    log_info "═══════════════════════════════════════════════════════════"
    
    echo ""
    get_log_stats
    echo ""
}

###############################################################################
# Menu system
###############################################################################
show_menu() {
    cat <<EOF

${YELLOW}┌─────────────────────────────────────────┐
│      AVAILABLE DEMONSTRATIONS          │
├─────────────────────────────────────────┤
│ 1) Run All Demos                        │
│ 2) Demo: Logging System                 │
│ 3) Demo: Vulnerability Analysis         │
│ 4) Demo: Report Generation              │
│ 5) Demo: Log Management                 │
│ 6) View Log Files                       │
│ 7) Clear All Logs                       │
│ 0) Exit                                 │
└─────────────────────────────────────────┘${NC}
EOF
}

###############################################################################
# View log files
###############################################################################
view_logs() {
    echo ""
    echo -e "${YELLOW}Select log to view:${NC}"
    echo "1) Main log (${LOG_FILE})"
    echo "2) Audit log (${AUDIT_LOG})"
    echo "3) Error log (${ERROR_LOG})"
    echo "0) Back"
    read -rp "Enter choice: " log_choice
    
    case "${log_choice}" in
        1) less "${LOG_FILE}" ;;
        2) less "${AUDIT_LOG}" ;;
        3) less "${ERROR_LOG}" ;;
        0) ;;
        *) log_error "Invalid choice" ;;
    esac
}

###############################################################################
# Main menu loop
###############################################################################
main_menu() {
    while true; do
        show_menu
        read -rp "Enter your choice (0-7): " choice
        
        case "${choice}" in
            1)
                demo_logging
                demo_vulnerability_analysis
                demo_report_generation
                demo_log_management
                read -rp "Press Enter to continue..."
                ;;
            2)
                demo_logging
                read -rp "Press Enter to continue..."
                ;;
            3)
                demo_vulnerability_analysis
                read -rp "Press Enter to continue..."
                ;;
            4)
                demo_report_generation
                read -rp "Press Enter to continue..."
                ;;
            5)
                demo_log_management
                read -rp "Press Enter to continue..."
                ;;
            6)
                view_logs
                ;;
            7)
                log_info "Clearing all logs..."
                clear_logs "all"
                log_info "Logs cleared successfully"
                read -rp "Press Enter to continue..."
                ;;
            0)
                log_info "Exiting demonstration. Final log statistics:"
                get_log_stats
                log_info "Thank you for using Airgeddon Improvements!"
                exit 0
                ;;
            *)
                log_error "Invalid choice: ${choice}"
                read -rp "Press Enter to continue..."
                ;;
        esac
        
        clear
        display_welcome
    done
}

###############################################################################
# Main execution
###############################################################################
main() {
    # Initialize logging
    initialize_logging
    
    # Display welcome message
    display_welcome
    
    log_info "Starting Airgeddon Improvements Demo"
    log_info "User: $(whoami)"
    log_info "Time: $(date)"
    log_info "System: $(uname -a | cut -d' ' -f1-2)"
    
    # Show main menu
    main_menu
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
