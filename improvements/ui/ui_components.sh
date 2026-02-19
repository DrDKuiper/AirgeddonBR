#!/bin/bash

################################################################################
# Airgeddon Improvements - TUI Components
# 
# Purpose: Reusable UI components for building terminal-based interfaces
# Version: 1.0
# License: GPL3
# 
# Description:
#   Provides functions for creating tables, menus, dialogs, and other UI
#   elements in pure Bash with support for colors and formatting.
################################################################################

set -o pipefail

# ============================================================================
# COLORS AND FORMATTING
# ============================================================================

declare -r COLOR_RESET='\033[0m'
declare -r COLOR_BOLD='\033[1m'
declare -r COLOR_DIM='\033[2m'
declare -r COLOR_UNDERLINE='\033[4m'

# Foreground colors
declare -r FG_BLACK='\033[30m'
declare -r FG_RED='\033[31m'
declare -r FG_GREEN='\033[32m'
declare -r FG_YELLOW='\033[33m'
declare -r FG_BLUE='\033[34m'
declare -r FG_MAGENTA='\033[35m'
declare -r FG_CYAN='\033[36m'
declare -r FG_WHITE='\033[37m'

# Background colors
declare -r BG_BLACK='\033[40m'
declare -r BG_RED='\033[41m'
declare -r BG_GREEN='\033[42m'
declare -r BG_YELLOW='\033[43m'
declare -r BG_BLUE='\033[44m'
declare -r BG_MAGENTA='\033[45m'
declare -r BG_CYAN='\033[46m'
declare -r BG_WHITE='\033[47m'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Get terminal width
get_terminal_width() {
    local width
    width=$(tput cols 2>/dev/null || echo 80)
    echo "$width"
}

# Get terminal height
get_terminal_height() {
    local height
    height=$(tput lines 2>/dev/null || echo 24)
    echo "$height"
}

# Check if terminal supports colors
supports_colors() {
    local colors
    colors=$(tput colors 2>/dev/null || echo 0)
    [[ $colors -ge 8 ]] && return 0 || return 1
}

# Clear screen
clear_screen() {
    tput clear 2>/dev/null || printf '\033[2J'
}

# Move cursor to position
cursor_position() {
    local row=$1
    local col=$2
    tput cup "$row" "$col" 2>/dev/null || printf '\033[%d;%dH' "$row" "$col"
}

# Hide cursor
hide_cursor() {
    tput civis 2>/dev/null || printf '\033[?25l'
}

# Show cursor
show_cursor() {
    tput cnorm 2>/dev/null || printf '\033[?25h'
}

# ============================================================================
# TEXT STYLING
# ============================================================================

# Center text on screen
center_text() {
    local text="$1"
    local width
    width=$(get_terminal_width)
    local text_width=${#text}
    local padding=$(( (width - text_width) / 2 ))
    
    printf "%*s%s\n" "$padding" "" "$text"
}

# Right-align text
right_align_text() {
    local text="$1"
    local width
    width=$(get_terminal_width)
    local text_width=${#text}
    local padding=$(( width - text_width ))
    
    printf "%*s%s\n" "$padding" "" "$text"
}

# Pad text to width
pad_text() {
    local text="$1"
    local width=$2
    local padding=$(( width - ${#text} ))
    
    if [[ $padding -lt 0 ]]; then
        echo "${text:0:$width}"
    else
        printf "%s%*s" "$text" "$padding" ""
    fi
}

# ============================================================================
# BOXES AND BORDERS
# ============================================================================

# Draw horizontal line
draw_line() {
    local width=${1:-$(get_terminal_width)}
    local char="${2:--}"
    
    printf '%*s\n' "$width" | tr ' ' "$char"
}

# Draw simple box
draw_box() {
    local title="$1"
    local width=${2:-$(get_terminal_width)}
    local title_len=${#title}
    local inner_width=$(( width - 2 ))
    
    # Top border
    printf "┌%*s┐\n" "$inner_width" | tr ' ' '─'
    
    # Title row if provided
    if [[ -n "$title" ]]; then
        local left_pad=$(( (inner_width - title_len) / 2 ))
        local right_pad=$(( inner_width - title_len - left_pad ))
        printf "│%*s%s%*s│\n" "$left_pad" "" "$title" "$right_pad" ""
        
        # Separator
        printf "├%*s┤\n" "$inner_width" | tr ' ' '─'
    fi
}

# Draw box bottom
draw_box_bottom() {
    local width=${1:-$(get_terminal_width)}
    local inner_width=$(( width - 2 ))
    
    printf "└%*s┘\n" "$inner_width" | tr ' ' '─'
}

# ============================================================================
# TABLES
# ============================================================================

# Create simple table header
table_header() {
    local -n cols=$1
    local width=${2:-$(get_terminal_width)}
    local num_cols=${#cols[@]}
    
    # Calculate column widths
    local col_width=$(( (width - num_cols - 1) / num_cols ))
    
    # Draw top border
    draw_line "$width" "─"
    
    # Draw header row
    printf "│"
    for col in "${cols[@]}"; do
        printf " $(pad_text "$col" $((col_width - 1))) │"
    done
    printf "\n"
    
    # Draw separator
    draw_line "$width" "─"
}

# Add table row
table_row() {
    local -n values=$1
    local width=${2:-$(get_terminal_width)}
    local num_cols=${#values[@]}
    
    local col_width=$(( (width - num_cols - 1) / num_cols ))
    
    printf "│"
    for val in "${values[@]}"; do
        printf " $(pad_text "$val" $((col_width - 1))) │"
    done
    printf "\n"
}

# Draw simple table with data
draw_table() {
    local title="$1"
    local -n column_names=$2
    local -n table_data=$3
    local width=${4:-$(get_terminal_width)}
    
    # Header
    draw_box "$title" "$width"
    table_header column_names "$width"
    
    # Data rows
    for row in "${table_data[@]}"; do
        IFS='|' read -ra cells <<< "$row"
        table_row cells "$width"
    done
    
    # Footer
    draw_line "$width" "─"
}

# ============================================================================
# MENUS
# ============================================================================

# Simple menu display
display_menu() {
    local title="$1"
    shift
    local -a options=("$@")
    
    clear_screen
    echo ""
    center_text "${COLOR_BOLD}${COLOR_CYAN}=== $title ===${COLOR_RESET}"
    echo ""
    
    local i=1
    for option in "${options[@]}"; do
        printf "${FG_GREEN}%2d)${COLOR_RESET} %s\n" "$i" "$option"
        ((i++))
    done
    echo ""
}

# Simple selection prompt
select_option() {
    local prompt="$1"
    local num_options=$2
    local choice
    
    while true; do
        read -p "$(printf "${FG_GREEN}%s${COLOR_RESET}" "$prompt")" choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 && $choice -le $num_options ]]; then
            echo "$choice"
            return 0
        else
            printf "${FG_RED}Opção inválida. Tente novamente.${COLOR_RESET}\n"
        fi
    done
}

# ============================================================================
# PROGRESS INDICATORS
# ============================================================================

# Simple progress bar
progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-40}
    
    local percent=$(( (current * 100) / total ))
    local filled=$(( (width * current) / total ))
    
    printf "["
    for ((i = 0; i < filled; i++)); do printf "="; done
    for ((i = filled; i < width; i++)); do printf " "; done
    printf "] %3d%%\n" "$percent"
}

# Spinner animation
spinner_start() {
    local msg="${1:-Processing...}"
    declare -g SPINNER_PID=""
    
    (
        local chars=( '|' '/' '-' '\' )
        local i=0
        while true; do
            printf "\r${FG_CYAN}%s ${chars[$((i % 4))]}${COLOR_RESET}" "$msg"
            ((i++))
            sleep 0.1
        done
    ) &
    
    SPINNER_PID=$!
}

# Stop spinner
spinner_stop() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        printf "\r%*s\r" 50 ""  # Clear line
        SPINNER_PID=""
    fi
}

# ============================================================================
# STATUS DISPLAYS
# ============================================================================

# Success message
show_success() {
    local msg="$1"
    printf "${FG_GREEN}✓${COLOR_RESET} %s\n" "$msg"
}

# Error message
show_error() {
    local msg="$1"
    printf "${FG_RED}✗${COLOR_RESET} %s\n" "$msg"
}

# Warning message
show_warning() {
    local msg="$1"
    printf "${FG_YELLOW}⚠${COLOR_RESET} %s\n" "$msg"
}

# Info message
show_info() {
    local msg="$1"
    printf "${FG_BLUE}ℹ${COLOR_RESET} %s\n" "$msg"
}

# ============================================================================
# DIALOG FUNCTIONS
# ============================================================================

# Confirm dialog
confirm_dialog() {
    local message="$1"
    local response
    
    printf "${FG_CYAN}%s${COLOR_RESET} " "$message"
    read -r -p "[${FG_GREEN}S${COLOR_RESET}/${FG_RED}N${COLOR_RESET}] " response
    
    case "$response" in
        [Ss] | [Yy] | "sim" | "yes" ) return 0 ;;
        * ) return 1 ;;
    esac
}

# Input dialog
input_dialog() {
    local prompt="$1"
    local default="${2:-}"
    local response
    
    if [[ -n "$default" ]]; then
        read -r -p "$(printf "${FG_CYAN}%s${COLOR_RESET} [${FG_YELLOW}%s${COLOR_RESET}]: " "$prompt" "$default")" response
        echo "${response:-$default}"
    else
        read -r -p "$(printf "${FG_CYAN}%s${COLOR_RESET}: " "$prompt")" response
        echo "$response"
    fi
}

# ============================================================================
# UTILITIES
# ============================================================================

# Truncate text with ellipsis
truncate_text() {
    local text="$1"
    local max_len=$2
    
    if [[ ${#text} -gt $max_len ]]; then
        echo "${text:0:$((max_len - 3))}..."
    else
        echo "$text"
    fi
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$(( bytes / 1024 ))KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$(( bytes / 1048576 ))MB"
    else
        echo "$(( bytes / 1073741824 ))GB"
    fi
}

# Export all functions
export -f get_terminal_width
export -f get_terminal_height
export -f supports_colors
export -f clear_screen
export -f cursor_position
export -f hide_cursor
export -f show_cursor
export -f center_text
export -f right_align_text
export -f pad_text
export -f draw_line
export -f draw_box
export -f draw_box_bottom
export -f table_header
export -f table_row
export -f draw_table
export -f display_menu
export -f select_option
export -f progress_bar
export -f spinner_start
export -f spinner_stop
export -f show_success
export -f show_error
export -f show_warning
export -f show_info
export -f confirm_dialog
export -f input_dialog
export -f truncate_text
export -f format_bytes
