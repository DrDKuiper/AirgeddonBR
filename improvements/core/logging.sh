#!/usr/bin/env bash

################################################################################
# Airgeddon Logging System
# Provides structured logging with levels, timestamps and file output
# Version: 1.0
# Usage: source logging.sh
################################################################################

# Color codes for terminal output
readonly COLOR_DEBUG='\033[0;36m'      # Cyan
readonly COLOR_INFO='\033[0;32m'       # Green
readonly COLOR_WARN='\033[0;33m'       # Yellow
readonly COLOR_ERROR='\033[0;31m'      # Red
readonly COLOR_CRITICAL='\033[1;31m'   # Bold Red
readonly COLOR_RESET='\033[0m'         # Reset

# Log levels
declare -gA LOG_LEVELS=(
    ['DEBUG']=0
    ['INFO']=1
    ['WARN']=2
    ['ERROR']=3
    ['CRITICAL']=4
)

# Current log level (default: INFO)
LOG_LEVEL="${LOG_LEVEL:-1}"

# Log file paths
LOG_FILE="${LOG_FILE:-.airgeddon_logs.txt}"
AUDIT_LOG="${AUDIT_LOG:-.airgeddon_audit.log}"
ERROR_LOG="${ERROR_LOG:-.airgeddon_error.log}"

# Enable/disable features
ENABLE_FILE_LOG="${ENABLE_FILE_LOG:-true}"
ENABLE_CONSOLE_LOG="${ENABLE_CONSOLE_LOG:-true}"
ENABLE_TIMESTAMPS="${ENABLE_TIMESTAMPS:-true}"
ENABLE_COLORS="${ENABLE_COLORS:-true}"

###############################################################################
# Initialize logging system
# Creates necessary log files and directories
###############################################################################
initialize_logging() {
    local log_dir="$(dirname "${LOG_FILE}")"
    
    # Create log directory if it doesn't exist
    [[ ! -d "${log_dir}" ]] && mkdir -p "${log_dir}"
    
    # Initialize log files
    touch "${LOG_FILE}" "${AUDIT_LOG}" "${ERROR_LOG}" 2>/dev/null
    
    # Set proper permissions
    chmod 600 "${LOG_FILE}" "${AUDIT_LOG}" "${ERROR_LOG}" 2>/dev/null
    
    # Log initialization
    _log_internal "INFO" "Logging system initialized"
}

###############################################################################
# Internal logging function (no recursion)
# Arguments:
#   $1 - Log level (DEBUG|INFO|WARN|ERROR|CRITICAL)
#   $2 - Message
#   $3 - Source function (optional)
###############################################################################
_log_internal() {
    local level="$1"
    local message="$2"
    local source="${3:-${FUNCNAME[2]}}"
    local timestamp=""
    
    # Ensure level is uppercase
    level="${level^^}"
    
    # Check if level should be logged
    [[ "${LOG_LEVELS[$level]:-1}" -lt "$LOG_LEVEL" ]] && return 0
    
    # Generate timestamp if enabled
    if [[ "${ENABLE_TIMESTAMPS}" == "true" ]]; then
        timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    # Format log entry
    local log_entry=""
    if [[ -n "${timestamp}" ]]; then
        log_entry="[${timestamp}] [${level}] [${source}] ${message}"
    else
        log_entry="[${level}] [${source}] ${message}"
    fi
    
    # Write to file if enabled
    if [[ "${ENABLE_FILE_LOG}" == "true" ]]; then
        echo "${log_entry}" >> "${LOG_FILE}" 2>/dev/null
    fi
    
    # Special handling for audit and error logs
    if [[ "${level}" == "ERROR" || "${level}" == "CRITICAL" ]]; then
        echo "${log_entry}" >> "${ERROR_LOG}" 2>/dev/null
    fi
    
    if [[ "${level}" == "WARN" || "${level}" == "ERROR" ]]; then
        echo "[AUDIT] ${log_entry}" >> "${AUDIT_LOG}" 2>/dev/null
    fi
    
    # Write to console if enabled
    if [[ "${ENABLE_CONSOLE_LOG}" == "true" ]]; then
        _print_to_console "${level}" "${log_entry}"
    fi
}

###############################################################################
# Print formatted output to console with colors
###############################################################################
_print_to_console() {
    local level="$1"
    local message="$2"
    local color
    
    if [[ "${ENABLE_COLORS}" == "true" ]]; then
        case "${level}" in
            DEBUG)    color="${COLOR_DEBUG}" ;;
            INFO)     color="${COLOR_INFO}" ;;
            WARN)     color="${COLOR_WARN}" ;;
            ERROR)    color="${COLOR_ERROR}" ;;
            CRITICAL) color="${COLOR_CRITICAL}" ;;
            *)        color="${COLOR_RESET}" ;;
        esac
        echo -e "${color}${message}${COLOR_RESET}" >&2
    else
        echo "${message}" >&2
    fi
}

###############################################################################
# Log debug message
# Arguments: $@ - Message to log
###############################################################################
log_debug() {
    _log_internal "DEBUG" "$*"
}

###############################################################################
# Log info message
# Arguments: $@ - Message to log
###############################################################################
log_info() {
    _log_internal "INFO" "$*"
}

###############################################################################
# Log warning message
# Arguments: $@ - Message to log
###############################################################################
log_warn() {
    _log_internal "WARN" "$*"
}

###############################################################################
# Log error message
# Arguments: $@ - Message to log
###############################################################################
log_error() {
    _log_internal "ERROR" "$*"
}

###############################################################################
# Log critical error message
# Arguments: $@ - Message to log
###############################################################################
log_critical() {
    _log_internal "CRITICAL" "$*"
}

###############################################################################
# Log command execution and result
# Arguments:
#   $1 - Command description
#   $2 - Command to execute
###############################################################################
log_command_execution() {
    local description="$1"
    local command="$2"
    
    log_info "Executing: ${description}"
    log_debug "Command: ${command}"
    
    # Execute command and capture output
    local output
    local exit_code
    
    output=$(eval "${command}" 2>&1)
    exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        log_info "✓ ${description} completed successfully"
        log_debug "Output: ${output}"
    else
        log_error "✗ ${description} failed (exit code: ${exit_code})"
        log_error "Output: ${output}"
    fi
    
    return ${exit_code}
}

###############################################################################
# Log function entry/exit for debugging
# Arguments: $1 - Function name
###############################################################################
log_function_entry() {
    local func_name="$1"
    log_debug "→ Entering function: ${func_name} (line ${BASH_LINENO[0]})"
}

log_function_exit() {
    local func_name="$1"
    local exit_code="${2:-0}"
    log_debug "← Exiting function: ${func_name} (exit code: ${exit_code}, line ${BASH_LINENO[0]})"
}

###############################################################################
# Set log level
# Arguments: $1 - Log level (DEBUG|INFO|WARN|ERROR|CRITICAL)
###############################################################################
set_log_level() {
    local level="${1^^}"
    
    if [[ ! -v LOG_LEVELS[$level] ]]; then
        log_error "Invalid log level: $1"
        return 1
    fi
    
    LOG_LEVEL="${LOG_LEVELS[$level]}"
    log_info "Log level changed to: ${level}"
    return 0
}

###############################################################################
# Get current log level name
###############################################################################
get_log_level() {
    for level in "${!LOG_LEVELS[@]}"; do
        if [[ ${LOG_LEVELS[$level]} -eq $LOG_LEVEL ]]; then
            echo "${level}"
            return
        fi
    done
}

###############################################################################
# Clear log files
# Arguments: $1 - Type (all|main|audit|error)
###############################################################################
clear_logs() {
    local type="${1:-all}"
    
    case "${type}" in
        all)
            > "${LOG_FILE}"
            > "${AUDIT_LOG}"
            > "${ERROR_LOG}"
            log_info "All logs cleared"
            ;;
        main)
            > "${LOG_FILE}"
            log_info "Main log cleared"
            ;;
        audit)
            > "${AUDIT_LOG}"
            log_info "Audit log cleared"
            ;;
        error)
            > "${ERROR_LOG}"
            log_info "Error log cleared"
            ;;
        *)
            log_error "Invalid log type: ${type}"
            return 1
            ;;
    esac
}

###############################################################################
# Get log statistics
###############################################################################
get_log_stats() {
    local total_lines total_debug total_info total_warn total_error total_critical
    
    total_lines=$(wc -l < "${LOG_FILE}" 2>/dev/null || echo 0)
    total_debug=$(grep -c '\[DEBUG\]' "${LOG_FILE}" 2>/dev/null || echo 0)
    total_info=$(grep -c '\[INFO\]' "${LOG_FILE}" 2>/dev/null || echo 0)
    total_warn=$(grep -c '\[WARN\]' "${LOG_FILE}" 2>/dev/null || echo 0)
    total_error=$(grep -c '\[ERROR\]' "${LOG_FILE}" 2>/dev/null || echo 0)
    total_critical=$(grep -c '\[CRITICAL\]' "${LOG_FILE}" 2>/dev/null || echo 0)
    
    cat <<EOF
╔════════════════════════════════════════╗
║         LOG STATISTICS                 ║
╠════════════════════════════════════════╣
║ Total lines:    ${total_lines:>25} │
║ Debug:          ${total_debug:>25} │
║ Info:           ${total_info:>25} │
║ Warnings:       ${total_warn:>25} │
║ Errors:         ${total_error:>25} │
║ Critical:       ${total_critical:>25} │
╚════════════════════════════════════════╝
EOF
}

###############################################################################
# Tail log file in real-time
# Arguments: $1 - Number of lines (default: 10)
###############################################################################
tail_logs() {
    local lines="${1:-10}"
    tail -f -n "${lines}" "${LOG_FILE}"
}

# Initialize logging system on sourcing
initialize_logging

return 0 2>/dev/null || true
