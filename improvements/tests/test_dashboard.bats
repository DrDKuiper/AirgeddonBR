#!/usr/bin/env bats

################################################################################
# Airgeddon Improvements - Dashboard Tests
# 
# Purpose: Test TUI dashboard components and functionality
# Framework: BATS (Bash Automated Testing System)
################################################################################

# Setup test environment
setup() {
    export TEST_DIR=$(mktemp -d)
    export TEST_LOG="${TEST_DIR}/test.log"
    
    # Source modules
    source "${BATS_TEST_DIRNAME}/../ui/ui_components.sh"
    source "${BATS_TEST_DIRNAME}/../ui/tui_manager.sh"
    source "${BATS_TEST_DIRNAME}/../ui/network_viewer.sh"
}

# Cleanup after tests
teardown() {
    rm -rf "$TEST_DIR"
}

# ============================================================================
# UI COMPONENTS TESTS
# ============================================================================

@test "get_terminal_width returns positive value" {
    local width
    width=$(get_terminal_width)
    [[ "$width" =~ ^[0-9]+$ ]] && [[ $width -gt 0 ]]
}

@test "get_terminal_height returns positive value" {
    local height
    height=$(get_terminal_height)
    [[ "$height" =~ ^[0-9]+$ ]] && [[ $height -gt 0 ]]
}

@test "pad_text pads correctly" {
    local result
    result=$(pad_text "test" 10)
    [[ ${#result} -eq 10 ]]
}

@test "truncate_text shortens long strings" {
    local result
    result=$(truncate_text "this is a very long string" 10)
    [[ ${#result} -le 10 ]]
    [[ "$result" == *"..."* ]]
}

@test "format_bytes converts B correctly" {
    local result
    result=$(format_bytes 512)
    [[ "$result" == "512B" ]]
}

@test "format_bytes converts KB correctly" {
    local result
    result=$(format_bytes 2048)
    [[ "$result" == "2KB" ]]
}

@test "format_bytes converts MB correctly" {
    local result
    result=$(format_bytes 2097152)
    [[ "$result" == "2MB" ]]
}

# ============================================================================
# TUI MANAGER TESTS
# ============================================================================

@test "initialize_tui sets state flag" {
    initialize_tui "echo"
    [[ $TUI_STATE_INITIALIZED -eq 1 ]]
}

@test "initialize_tui returns success" {
    initialize_tui "echo"
    [[ $? -eq 0 ]]
}

@test "change_view updates current view" {
    initialize_tui "echo"
    change_view "networks"
    [[ "$CURRENT_VIEW" == "networks" ]]
}

@test "change_view saves previous view" {
    initialize_tui "echo"
    change_view "home"
    change_view "settings"
    [[ "$PREVIOUS_VIEW" == "home" ]]
}

@test "get_current_view returns correct view" {
    initialize_tui "echo"
    change_view "test_view"
    [[ "$(get_current_view)" == "test_view" ]]
}

@test "set_context stores key-value pair" {
    set_context "test_key" "test_value"
    [[ "$(get_context 'test_key')" == "test_value" ]]
}

@test "get_context returns default for missing key" {
    [[ "$(get_context 'nonexistent' 'default')" == "default" ]]
}

@test "set_status works" {
    set_status "Test message" "info"
    [[ "$(get_status)" == "Test message" ]]
}

@test "get_status_type returns correct type" {
    set_status "Test" "error"
    [[ "$(get_status_type)" == "error" ]]
}

@test "enable_auto_refresh sets flag" {
    enable_auto_refresh 5
    [[ $AUTO_REFRESH -eq 1 ]]
    [[ $REFRESH_INTERVAL -eq 5 ]]
}

@test "is_auto_refresh_enabled returns correct value" {
    enable_auto_refresh
    is_auto_refresh_enabled
    [[ $? -eq 0 ]]
}

@test "disable_auto_refresh unsets flag" {
    enable_auto_refresh
    disable_auto_refresh
    [[ $AUTO_REFRESH -eq 0 ]]
}

@test "set_tui_mode accepts valid modes" {
    set_tui_mode "interactive"
    [[ "$(get_tui_mode)" == "interactive" ]]
}

@test "set_tui_mode rejects invalid modes" {
    set_tui_mode "invalid_mode"
    [[ $? -ne 0 ]]
}

# ============================================================================
# NETWORK VIEWER TESTS
# ============================================================================

@test "add_network creates new network entry" {
    add_network "AA:BB:CC:DD:EE:FF" "TestSSID" "WPA2" "-50dBm" "6"
    [[ "${NETWORKS[AA:BB:CC:DD:EE:FF_bssid]}" == "AA:BB:CC:DD:EE:FF" ]]
}

@test "add_network stores all fields correctly" {
    add_network "AA:BB:CC:DD:EE:FF" "TestSSID" "WPA2" "-50dBm" "6"
    [[ "${NETWORKS[AA:BB:CC:DD:EE:FF_essid]}" == "TestSSID" ]]
    [[ "${NETWORKS[AA:BB:CC:DD:EE:FF_encryption]}" == "WPA2" ]]
    [[ "${NETWORKS[AA:BB:CC:DD:EE:FF_signal]}" == "-50dBm" ]]
    [[ "${NETWORKS[AA:BB:CC:DD:EE:FF_channel]}" == "6" ]]
}

@test "get_network_data retrieves correct values" {
    add_network "AA:BB:CC:DD:EE:FF" "TestSSID" "WPA2" "-50dBm" "6"
    [[ "$(get_network_data 'AA:BB:CC:DD:EE:FF' 'essid')" == "TestSSID" ]]
}

@test "remove_network deletes network" {
    add_network "AA:BB:CC:DD:EE:FF" "TestSSID" "WPA2" "-50dBm" "6"
    remove_network "AA:BB:CC:DD:EE:FF"
    [[ -z "${NETWORKS[AA:BB:CC:DD:EE:FF_bssid]}" ]]
}

@test "clear_networks removes all networks" {
    add_network "AA:BB:CC:DD:EE:FF" "Test1" "WPA2" "-50dBm" "6"
    add_network "AA:BB:CC:DD:EE:01" "Test2" "WPA3" "-45dBm" "11"
    clear_networks
    [[ ${#NETWORK_LIST[@]} -eq 0 ]]
}

@test "get_network_count returns correct count" {
    add_network "AA:BB:CC:DD:EE:01" "Test1" "WPA2" "-50dBm" "6"
    add_network "AA:BB:CC:DD:EE:02" "Test2" "WPA3" "-45dBm" "11"
    [[ $(get_network_count) -eq 2 ]]
}

@test "sort_networks by signal works" {
    add_network "AA:BB:CC:DD:EE:01" "Test1" "WPA2" "-70dBm" "6"
    add_network "AA:BB:CC:DD:EE:02" "Test2" "WPA3" "-30dBm" "11"
    add_network "AA:BB:CC:DD:EE:03" "Test3" "WPA2" "-50dBm" "1"
    
    sort_networks "signal" "desc"
    
    # First network should be -30dBm
    [[ "${NETWORK_LIST[0]}" == "AA:BB:CC:DD:EE:02" ]]
}

@test "sort_networks by ssid works" {
    add_network "AA:BB:CC:DD:EE:01" "Zebra" "WPA2" "-50dBm" "6"
    add_network "AA:BB:CC:DD:EE:02" "Alpha" "WPA3" "-45dBm" "11"
    add_network "AA:BB:CC:DD:EE:03" "Beta" "WPA2" "-60dBm" "1"
    
    sort_networks "ssid" "asc"
    
    # First should be Alpha
    [[ "${NETWORKS[${NETWORK_LIST[0]}_essid]}" == "Alpha" ]]
}

@test "set_encryption_filter filters networks" {
    add_network "AA:BB:CC:DD:EE:01" "Test1" "WPA2" "-50dBm" "6"
    add_network "AA:BB:CC:DD:EE:02" "Test2" "WPA3" "-45dBm" "11"
    add_network "AA:BB:CC:DD:EE:03" "Test3" "WPA2" "-60dBm" "1"
    
    set_encryption_filter "WPA2"
    local -a visible
    mapfile -t visible < <(get_visible_networks)
    
    [[ ${#visible[@]} -eq 2 ]]
}

@test "clear_filter shows all networks" {
    add_network "AA:BB:CC:DD:EE:01" "Test1" "WPA2" "-50dBm" "6"
    add_network "AA:BB:CC:DD:EE:02" "Test2" "WPA3" "-45dBm" "11"
    
    set_encryption_filter "WPA2"
    clear_filter
    local -a visible
    mapfile -t visible < <(get_visible_networks)
    
    [[ ${#visible[@]} -eq 2 ]]
}

@test "signal_to_level converts weak signal" {
    local level
    level=$(signal_to_level "-90dBm")
    [[ "$level" == "Fraco" ]]
}

@test "signal_to_level converts strong signal" {
    local level
    level=$(signal_to_level "-35dBm")
    [[ "$level" == "Excelente" ]]
}

@test "signal_to_level converts medium signal" {
    local level
    level=$(signal_to_level "-60dBm")
    [[ "$level" == "Bom" ]]
}

@test "select_next_network increments selection" {
    add_network "AA:BB:CC:DD:EE:01" "Test1" "WPA2" "-50dBm" "6"
    add_network "AA:BB:CC:DD:EE:02" "Test2" "WPA3" "-45dBm" "11"
    
    SELECTED_NETWORK_IDX=0
    select_next_network
    [[ $SELECTED_NETWORK_IDX -eq 1 ]]
}

@test "select_previous_network decrements selection" {
    add_network "AA:BB:CC:DD:EE:01" "Test1" "WPA2" "-50dBm" "6"
    add_network "AA:BB:CC:DD:EE:02" "Test2" "WPA3" "-45dBm" "11"
    
    SELECTED_NETWORK_IDX=1
    select_previous_network
    [[ $SELECTED_NETWORK_IDX -eq 0 ]]
}

@test "get_selected_network returns current selection" {
    add_network "AA:BB:CC:DD:EE:01" "Test1" "WPA2" "-50dBm" "6"
    add_network "AA:BB:CC:DD:EE:02" "Test2" "WPA3" "-45dBm" "11"
    
    SELECTED_NETWORK_IDX=0
    [[ "$(get_selected_network)" == "AA:BB:CC:DD:EE:01" ]]
}

@test "get_average_signal calculates correctly" {
    add_network "AA:BB:CC:DD:EE:01" "Test1" "WPA2" "-60dBm" "6"
    add_network "AA:BB:CC:DD:EE:02" "Test2" "WPA3" "-40dBm" "11"
    
    local avg
    avg=$(get_average_signal)
    # Average of -60 and -40 is -50
    [[ $avg -eq -50 ]]
}

# ============================================================================
# EDGE CASES AND INTEGRATION
# ============================================================================

@test "dashboard handles empty network list" {
    [[ $(get_network_count) -eq 0 ]]
}

@test "dashboard handles special characters in SSID" {
    local special_ssid='TestSSID!@#$%&*()'
    add_network "AA:BB:CC:DD:EE:FF" "$special_ssid" "WPA2" "-50dBm" "6"
    [[ "$(get_network_data 'AA:BB:CC:DD:EE:FF' 'essid')" == "$special_ssid" ]]
}

@test "dashboard handles long SSID" {
    local long_ssid=$(printf 'A%.0s' {1..50})
    add_network "AA:BB:CC:DD:EE:FF" "$long_ssid" "WPA2" "-50dBm" "6"
    [[ "$(get_network_data 'AA:BB:CC:DD:EE:FF' 'essid')" == "$long_ssid" ]]
}

@test "dashboard maintains network order in list" {
    add_network "AA:BB:CC:DD:EE:01" "Test1" "WPA2" "-50dBm" "6"
    add_network "AA:BB:CC:DD:EE:02" "Test2" "WPA3" "-45dBm" "11"
    add_network "AA:BB:CC:DD:EE:03" "Test3" "WPA2" "-60dBm" "1"
    
    [[ "${NETWORK_LIST[0]}" == "AA:BB:CC:DD:EE:01" ]]
    [[ "${NETWORK_LIST[1]}" == "AA:BB:CC:DD:EE:02" ]]
    [[ "${NETWORK_LIST[2]}" == "AA:BB:CC:DD:EE:03" ]]
}

@test "create_session generates unique session ID" {
    local session1
    local session2
    session1=$(create_session)
    sleep 0.1
    session2=$(create_session)
    [[ "$session1" != "$session2" ]]
}

@test "get_session_duration returns positive value" {
    create_session
    sleep 0.1
    local duration
    duration=$(get_session_duration)
    [[ $duration -gt 0 ]]
}
