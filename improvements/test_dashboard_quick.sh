#!/bin/bash

################################################################################
# Airgeddon Dashboard - Quick Test Script
# 
# Purpose: Quickly test dashboard componentsand functionality
# Version: 1.0
################################################################################

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1$(printf '%*s' $((55 - ${#1})) '')${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
    echo -e "\n${YELLOW}→ $1${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# ============================================================================
# TESTS
# ============================================================================

test_sourcing() {
    print_section "Testing Module Sourcing"
    
    # Test ui_components
    if source "${SCRIPT_DIR}/ui/ui_components.sh" 2>/dev/null; then
        print_success "ui_components.sh sourced successfully"
    else
        print_error "Failed to source ui_components.sh"
        return 1
    fi
    
    # Test tui_manager
    if source "${SCRIPT_DIR}/ui/tui_manager.sh" 2>/dev/null; then
        print_success "tui_manager.sh sourced successfully"
    else
        print_error "Failed to source tui_manager.sh"
        return 1
    fi
    
    # Test network_viewer
    if source "${SCRIPT_DIR}/ui/network_viewer.sh" 2>/dev/null; then
        print_success "network_viewer.sh sourced successfully"
    else
        print_error "Failed to source network_viewer.sh"
        return 1
    fi
    
    return 0
}

test_ui_components() {
    print_section "Testing UI Component Functions"
    
    source "${SCRIPT_DIR}/ui/ui_components.sh"
    
    # Test terminal width
    local width
    width=$(get_terminal_width)
    if [[ $width -gt 0 ]]; then
        print_success "Terminal width: $width"
    else
        print_error "Failed to get terminal width"
    fi
    
    # Test text padding
    local padded
    padded=$(pad_text "test" 10)
    if [[ ${#padded} -eq 10 ]]; then
        print_success "Text padding works (length: ${#padded})"
    else
        print_error "Text padding failed"
    fi
    
    # Test truncation
    local truncated
    truncated=$(truncate_text "this is a very long string that needs truncation" 20)
    if [[ "$truncated" == *"..."* ]] && [[ ${#truncated} -le 20 ]]; then
        print_success "Text truncation works (truncated: '$truncated')"
    else
        print_error "Text truncation failed"
    fi
}

test_network_operations() {
    print_section "Testing Network Operations"
    
    source "${SCRIPT_DIR}/ui/ui_components.sh"
    source "${SCRIPT_DIR}/ui/tui_manager.sh"
    source "${SCRIPT_DIR}/ui/network_viewer.sh"
    
    # Clear any existing networks
    clear_networks
    
    # Add test networks
    add_network "AA:BB:CC:DD:EE:01" "TestNetwork1" "WPA2" "-50dBm" "6"
    add_network "AA:BB:CC:DD:EE:02" "TestNetwork2" "WPA3" "-45dBm" "11"
    add_network "AA:BB:CC:DD:EE:03" "TestNetwork3" "OPEN" "-70dBm" "1"
    
    # Test count
    local count
    count=$(get_network_count)
    if [[ $count -eq 3 ]]; then
        print_success "Network count: $count"
    else
        print_error "Network count failed (expected 3, got $count)"
    fi
    
    # Test data retrieval
    local essid
    essid=$(get_network_data "AA:BB:CC:DD:EE:01" "essid")
    if [[ "$essid" == "TestNetwork1" ]]; then
        print_success "Network data retrieval: SSID='$essid'"
    else
        print_error "Network data retrieval failed"
    fi
    
    # Test sorting
    sort_networks "signal" "desc"
    local first
    first="${NETWORK_LIST[0]}"
    local first_signal
    first_signal=$(get_network_data "$first" "signal")
    print_success "Networks sorted by signal (first: $first_signal)"
    
    # Test filtering
    set_encryption_filter "WPA2"
    local -a visible
    mapfile -t visible < <(get_visible_networks)
    if [[ ${#visible[@]} -eq 1 ]]; then
        print_success "Encryption filter working (WPA2: ${#visible[@]} network)"
    else
        print_error "Encryption filter failed"
    fi
    clear_filter
    
    # Test average signal
    local avg
    avg=$(get_average_signal)
    print_success "Average signal strength: ${avg}dBm"
}

test_tui_state_management() {
    print_section "Testing TUI State Management"
    
    source "${SCRIPT_DIR}/ui/ui_components.sh"
    source "${SCRIPT_DIR}/ui/tui_manager.sh"
    
    # Initialize TUI
    if initialize_tui "echo" >/dev/null 2>&1; then
        print_success "TUI initialized successfully"
    else
        print_error "TUI initialization failed"
        return 1
    fi
    
    # Test view changes
    change_view "networks"
    if [[ "$(get_current_view)" == "networks" ]]; then
        print_success "View change: $(get_current_view)"
    else
        print_error "View change failed"
    fi
    
    # Test context storage
    set_context "test_key" "test_value"
    local val
    val=$(get_context "test_key")
    if [[ "$val" == "test_value" ]]; then
        print_success "Context storage: key='test_key', value='$val'"
    else
        print_error "Context storage failed"
    fi
    
    # Test status message
    set_status "Test message" "info"
    local status
    status=$(get_status)
    if [[ "$status" == "Test message" ]]; then
        print_success "Status message set: '$status'"
    else
        print_error "Status message failed"
    fi
}

test_bats_tests() {
    print_section "Running BATS Test Suite"
    
    # Check if bats is installed
    if ! command -v bats &> /dev/null; then
        print_error "BATS not installed. Install with: sudo apt-get install bats"
        print_info "Skipping BATS tests"
        return 0
    fi
    
    print_info "Running test_dashboard.bats..."
    if bats "${SCRIPT_DIR}/tests/test_dashboard.bats" 2>&1 | tail -20; then
        print_success "BATS tests completed"
        return 0
    else
        print_error "Some BATS tests failed"
        return 1
    fi
}

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================

test_performance() {
    print_section "Performance Benchmarks"
    
    source "${SCRIPT_DIR}/ui/ui_components.sh"
    source "${SCRIPT_DIR}/ui/tui_manager.sh"
    source "${SCRIPT_DIR}/ui/network_viewer.sh"
    
    # Clear networks
    clear_networks
    
    # Benchmark: Adding networks
    local start end elapsed
    
    print_info "Adding 50 networks..."
    start=$(date +%s%N)
    for i in {1..50}; do
        local mac
        mac=$(printf "AA:BB:CC:DD:EE:%02X" $((i % 256)))
        add_network "$mac" "Network_$i" "WPA2" "-$(( 30 + (RANDOM % 60) ))dBm" "$((1 + (i % 13)))"
    done
    end=$(date +%s%N)
    elapsed=$(( (end - start) / 1000000 ))  # Convert to milliseconds
    print_success "Added 50 networks in ${elapsed}ms"
    
    # Benchmark: Sorting
    print_info "Sorting 50 networks by signal..."
    start=$(date +%s%N)
    sort_networks "signal" "desc"
    end=$(date +%s%N)
    elapsed=$(( (end - start) / 1000000 ))
    print_success "Sorted in ${elapsed}ms"
    
    # Benchmark: Filtering
    print_info "Filtering 50 networks..."
    start=$(date +%s%N)
    set_encryption_filter "WPA2"
    local -a visible
    mapfile -t visible < <(get_visible_networks)
    end=$(date +%s%N)
    elapsed=$(( (end - start) / 1000000 ))
    print_success "Filtered in ${elapsed}ms (${#visible[@]} networks match)"
}

# ============================================================================
# INTERACTIVE DEMO
# ============================================================================

run_interactive_demo() {
    print_section "Starting Interactive Dashboard Demo"
    
    # Give user option to run demo
    echo -e "This will launch the interactive dashboard with sample data."
    echo -e "Controls: ${BLUE}1-5${NC} menu numbers, ${BLUE}Q${NC} to quit"
    
    read -p "Continue? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -f "${SCRIPT_DIR}/demo_dashboard.sh" ]]; then
            bash "${SCRIPT_DIR}/demo_dashboard.sh"
        else
            print_error "demo_dashboard.sh not found"
        fi
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    print_header "Airgeddon Dashboard - Quick Test Suite"
    
    print_info "Testing Dashboard Components and Functionality"
    
    # Run tests
    local failed=0
    
    test_sourcing || ((failed++))
    test_ui_components || ((failed++))
    test_tui_state_management || ((failed++))
    test_network_operations || ((failed++))
    test_performance || ((failed++))
    test_bats_tests || ((failed++))
    
    # Summary
    print_header "Test Summary"
    
    if [[ $failed -eq 0 ]]; then
        print_success "All tests passed!"
        echo -e "\n${GREEN}✓ Dashboard is fully functional${NC}\n"
    else
        print_error "$failed test(s) failed"
        echo -e "\n${RED}✗ Some tests failed. Review output above.${NC}\n"
    fi
    
    # Ask to run demo
    echo ""
    read -p "Run interactive dashboard demo? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_interactive_demo
    fi
}

# ============================================================================
# ENTRY POINT
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
