#!/bin/bash

################################################################################
# Airgeddon Improvements - TUI Manager
# 
# Purpose: State management and lifecycle for TUI applications
# Version: 1.0
# License: GPL3
# 
# Description:
#   Manages application state, navigation history, and TUI lifecycle events.
################################################################################

set -o pipefail

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/ui_components.sh" || {
    echo "Error: Could not source ui_components.sh"
    exit 1
}

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

declare -g TUI_STATE_INITIALIZED=0
declare -g CURRENT_VIEW=""
declare -g PREVIOUS_VIEW=""
declare -g -A STATE_STACK
declare -g STATE_STACK_SIZE=0
declare -g TUI_MODE="interactive"  # interactive or batch
declare -g AUTO_REFRESH=0
declare -g REFRESH_INTERVAL=2

# ============================================================================
# INITIALIZATION
# ============================================================================

# Initialize TUI environment
initialize_tui() {
    local log_func="${1:-echo}"
    
    if [[ $TUI_STATE_INITIALIZED -eq 1 ]]; then
        $log_func "TUI already initialized"
        return 0
    fi
    
    # Set up signal handlers
    trap 'on_tui_exit' EXIT
    trap 'on_tui_interrupt' INT TERM
    
    # Hide cursor
    hide_cursor
    
    # Initialize state
    CURRENT_VIEW="home"
    PREVIOUS_VIEW=""
    TUI_STATE_INITIALIZED=1
    
    $log_func "TUI initialized successfully"
    return 0
}

# Cleanup on exit
on_tui_exit() {
    show_cursor
    clear_screen
}

# Handle interrupt (Ctrl+C)
on_tui_interrupt() {
    show_cursor
    clear_screen
    echo "Interrupção do usuário. Saindo..."
    exit 130
}

# ============================================================================
# VIEW MANAGEMENT
# ============================================================================

# Change to different view
change_view() {
    local new_view="$1"
    
    if [[ -n "$CURRENT_VIEW" ]]; then
        PREVIOUS_VIEW="$CURRENT_VIEW"
        STATE_STACK["$STATE_STACK_SIZE"]="$PREVIOUS_VIEW"
        ((STATE_STACK_SIZE++))
    fi
    
    CURRENT_VIEW="$new_view"
    return 0
}

# Go back to previous view
go_back() {
    if [[ $STATE_STACK_SIZE -gt 0 ]]; then
        ((STATE_STACK_SIZE--))
        PREVIOUS_VIEW="$CURRENT_VIEW"
        CURRENT_VIEW="${STATE_STACK[$STATE_STACK_SIZE]}"
        return 0
    fi
    return 1
}

# Get current view
get_current_view() {
    echo "$CURRENT_VIEW"
}

# Get previous view
get_previous_view() {
    echo "$PREVIOUS_VIEW"
}

# ============================================================================
# REFRESH MANAGEMENT
# ============================================================================

# Enable auto-refresh
enable_auto_refresh() {
    local interval="${1:-2}"
    AUTO_REFRESH=1
    REFRESH_INTERVAL="$interval"
}

# Disable auto-refresh
disable_auto_refresh() {
    AUTO_REFRESH=0
}

# Check if auto-refresh is enabled
is_auto_refresh_enabled() {
    [[ $AUTO_REFRESH -eq 1 ]] && return 0 || return 1
}

# ============================================================================
# MODE MANAGEMENT
# ============================================================================

# Set TUI mode
set_tui_mode() {
    local mode="$1"
    
    case "$mode" in
        interactive|batch)
            TUI_MODE="$mode"
            return 0
            ;;
        *)
            show_error "Invalid mode: $mode"
            return 1
            ;;
    esac
}

# Get TUI mode
get_tui_mode() {
    echo "$TUI_MODE"
}

# ============================================================================
# STATUS BAR
# ============================================================================

declare -g STATUS_MESSAGE=""
declare -g STATUS_TYPE="info"  # info, success, error, warning

# Set status message
set_status() {
    local message="$1"
    local type="${2:-info}"
    
    STATUS_MESSAGE="$message"
    STATUS_TYPE="$type"
}

# Get status message
get_status() {
    echo "$STATUS_MESSAGE"
}

# Get status type
get_status_type() {
    echo "$STATUS_TYPE"
}

# Render status bar
render_status_bar() {
    local width
    width=$(get_terminal_width)
    
    if [[ -z "$STATUS_MESSAGE" ]]; then
        return
    fi
    
    local prefix=""
    local color=""
    
    case "$STATUS_TYPE" in
        success)
            prefix="✓"
            color="$FG_GREEN"
            ;;
        error)
            prefix="✗"
            color="$FG_RED"
            ;;
        warning)
            prefix="⚠"
            color="$FG_YELLOW"
            ;;
        *)
            prefix="ℹ"
            color="$FG_BLUE"
            ;;
    esac
    
    local message="$prefix $STATUS_MESSAGE"
    local padded
    padded=$(pad_text "$message" "$((width - 2))")
    
    printf "${color}%s${COLOR_RESET}\n" "$padded"
}

# ============================================================================
# FOOTER/HELP
# ============================================================================

# Render help footer
render_footer() {
    local width
    width=$(get_terminal_width)
    
    local footer_text="[Q] Sair  [B] Voltar  [R] Atualizar"
    local padded
    padded=$(pad_text "$footer_text" "$width")
    
    printf "${BG_BLUE}${FG_WHITE}%s${COLOR_RESET}\n" "$padded"
}

# ============================================================================
# HEADER
# ============================================================================

# Render application header
render_header() {
    local title="$1"
    local subtitle="${2:-}"
    local width
    width=$(get_terminal_width)
    
    clear_screen
    echo ""
    center_text "${COLOR_BOLD}${COLOR_CYAN}╔═══════════════════════════════════════╗${COLOR_RESET}"
    center_text "${COLOR_BOLD}${COLOR_CYAN}║${COLOR_RESET}   ${COLOR_BOLD}Airgeddon WiFi Audit Dashboard${COLOR_RESET}   ${COLOR_BOLD}${COLOR_CYAN}║${COLOR_RESET}"
    center_text "${COLOR_BOLD}${COLOR_CYAN}╚═══════════════════════════════════════╝${COLOR_RESET}"
    echo ""
    
    if [[ -n "$title" ]]; then
        center_text "${COLOR_BOLD}${COLOR_YELLOW}>>> ${title}${COLOR_RESET}"
        
        if [[ -n "$subtitle" ]]; then
            center_text "${COLOR_DIM}${subtitle}${COLOR_RESET}"
        fi
        
        echo ""
    fi
}

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

declare -g SESSION_START_TIME
declare -g SESSION_ID

# Create new session
create_session() {
    SESSION_START_TIME=$(date +%s)
    SESSION_ID="session_$(date +%s%N)"
    
    echo "$SESSION_ID"
}

# Get session duration
get_session_duration() {
    local current_time
    current_time=$(date +%s)
    local duration=$(( current_time - SESSION_START_TIME ))
    
    echo "$duration"
}

# ============================================================================
# CONTEXT STORAGE
# ============================================================================

declare -g -A TUI_CONTEXT

# Store context value
set_context() {
    local key="$1"
    local value="$2"
    
    TUI_CONTEXT["$key"]="$value"
}

# Get context value
get_context() {
    local key="$1"
    local default="${2:-}"
    
    echo "${TUI_CONTEXT[$key]:-$default}"
}

# Clear context
clear_context() {
    unset TUI_CONTEXT
    declare -g -A TUI_CONTEXT
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

export -f initialize_tui
export -f change_view
export -f go_back
export -f get_current_view
export -f get_previous_view
export -f enable_auto_refresh
export -f disable_auto_refresh
export -f is_auto_refresh_enabled
export -f set_tui_mode
export -f get_tui_mode
export -f set_status
export -f get_status
export -f get_status_type
export -f render_status_bar
export -f render_footer
export -f render_header
export -f create_session
export -f get_session_duration
export -f set_context
export -f get_context
export -f clear_context
