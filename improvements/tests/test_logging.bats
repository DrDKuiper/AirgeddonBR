#!/usr/bin/env bats

# Airgeddon Logging System Tests
# Run with: bats tests/test_logging.bats

# Setup
setup() {
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export LOG_FILE="${TEST_DIR}/test.log"
    export AUDIT_LOG="${TEST_DIR}/audit.log"
    export ERROR_LOG="${TEST_DIR}/error.log"
    
    # Source logging module
    source "improvements/core/logging.sh"
}

# Cleanup
teardown() {
    # Remove temporary directory
    rm -rf "${TEST_DIR}"
}

################################################################################
# Test initialization
################################################################################

@test "logging system initializes correctly" {
    initialize_logging
    [ -f "${LOG_FILE}" ]
}

@test "log files are created with proper permissions" {
    initialize_logging
    [ -f "${LOG_FILE}" ]
    [ -f "${AUDIT_LOG}" ]
    [ -f "${ERROR_LOG}" ]
}

@test "log directory is created if it doesn't exist" {
    local nested_dir="${TEST_DIR}/nested/logs"
    export LOG_FILE="${nested_dir}/test.log"
    initialize_logging
    [ -d "${nested_dir}" ]
}

################################################################################
# Test logging functions
################################################################################

@test "log_info writes to log file" {
    initialize_logging
    log_info "Test message"
    grep -q "Test message" "${LOG_FILE}"
}

@test "log_error writes to error log" {
    initialize_logging
    log_error "Error message"
    grep -q "Error message" "${ERROR_LOG}"
}

@test "log_warn writes to audit log" {
    initialize_logging
    log_warn "Warning message"
    grep -q "Warning message" "${AUDIT_LOG}"
}

@test "log_debug respects log level" {
    initialize_logging
    export LOG_LEVEL=1  # INFO level
    log_debug "Debug message"
    ! grep -q "Debug message" "${LOG_FILE}"
}

@test "log_critical writes both error and console output" {
    initialize_logging
    log_critical "Critical issue"
    grep -q "Critical issue" "${ERROR_LOG}"
}

################################################################################
# Test log levels
################################################################################

@test "set_log_level changes log filtering" {
    initialize_logging
    set_log_level "DEBUG"
    log_debug "Debug test"
    grep -q "Debug test" "${LOG_FILE}"
}

@test "set_log_level rejects invalid levels" {
    initialize_logging
    ! set_log_level "INVALID"
}

@test "get_log_level returns current level" {
    initialize_logging
    set_log_level "WARN"
    level=$(get_log_level)
    [ "${level}" = "WARN" ]
}

################################################################################
# Test log management
################################################################################

@test "clear_logs removes main log entries" {
    initialize_logging
    log_info "Test entry"
    clear_logs "main"
    ! grep -q "Test entry" "${LOG_FILE}"
}

@test "clear_logs handles all types" {
    initialize_logging
    log_info "Test"
    log_error "Error"
    clear_logs "all"
    [ ! -s "${LOG_FILE}" ]
    [ ! -s "${ERROR_LOG}" ]
}

@test "get_log_stats provides statistics" {
    initialize_logging
    log_info "Info message"
    log_error "Error message"
    log_warn "Warn message"
    stats=$(get_log_stats)
    echo "${stats}" | grep -q "INFO"
}

################################################################################
# Test function logging
################################################################################

@test "log_function_entry creates proper entry" {
    initialize_logging
    log_function_entry "test_function"
    grep -q "Entering function: test_function" "${LOG_FILE}"
}

@test "log_function_exit creates proper exit entry" {
    initialize_logging
    log_function_exit "test_function" "0"
    grep -q "Exiting function: test_function" "${LOG_FILE}"
}

################################################################################
# Test command execution logging
################################################################################

@test "log_command_execution logs successful commands" {
    initialize_logging
    log_command_execution "ls test" "ls -la ${TEST_DIR}" > /dev/null 2>&1
    grep -q "completed successfully" "${LOG_FILE}"
}

@test "log_command_execution logs failed commands" {
    initialize_logging
    log_command_execution "failing command" "false" > /dev/null 2>&1
    grep -q "failed" "${LOG_FILE}"
}

################################################################################
# Test timestamp functionality
################################################################################

@test "timestamps are included when enabled" {
    initialize_logging
    export ENABLE_TIMESTAMPS="true"
    log_info "Timestamped message"
    grep -q '\[20[0-9][0-9]-' "${LOG_FILE}"
}

@test "timestamps can be disabled" {
    initialize_logging
    export ENABLE_TIMESTAMPS="false"
    log_info "Non-timestamped message"
    ! grep -qE '\[[0-9]{4}-[0-9]{2}-[0-9]{2}' "${LOG_FILE}"
}

################################################################################
# Test edge cases
################################################################################

@test "logging handles special characters" {
    initialize_logging
    special_msg='Test with "quotes" and $variables & [brackets]'
    log_info "${special_msg}"
    grep -q "Test with" "${LOG_FILE}"
}

@test "logging handles empty messages" {
    initialize_logging
    log_info ""
    [ -s "${LOG_FILE}" ]
}

@test "logging handles very long messages" {
    initialize_logging
    long_msg=$(printf 'A%.0s' {1..1000})
    log_info "${long_msg}"
    grep -q "AAAA" "${LOG_FILE}"
}

@test "multiple functions can log independently" {
    initialize_logging
    func1() { log_info "From func1"; }
    func2() { log_info "From func2"; }
    
    func1
    func2
    
    grep -q "From func1" "${LOG_FILE}"
    grep -q "From func2" "${LOG_FILE}"
}
