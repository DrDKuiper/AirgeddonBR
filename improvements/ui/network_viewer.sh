#!/bin/bash

################################################################################
# Airgeddon Improvements - Network Viewer
# 
# Purpose: Display and manage WiFi network information in TUI
# Version: 1.0
# License: GPL3
# 
# Description:
#   Provides visualization of discovered WiFi networks with real-time updates,
#   filtering, sorting, and detailed view modes.
################################################################################

set -o pipefail

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/ui_components.sh" || {
    echo "Error: Could not source ui_components.sh"
    exit 1
}

# ============================================================================
# DATA STRUCTURES
# ============================================================================

declare -g -A NETWORKS
declare -g -a NETWORK_LIST=()
declare -g SORT_BY="signal"  # signal, ssid, encryption, channel
declare -g SORT_ORDER="desc"  # asc, desc
declare -g FILTER_ENCRYPTION=""  # empty = all
declare -g SELECTED_NETWORK_IDX=0

# ============================================================================
# NETWORK MANAGEMENT
# ============================================================================

# Add network to viewer
add_network() {
    local bssid="$1"
    local essid="$2"
    local encryption="$3"
    local signal="$4"
    local channel="${5:-1}"
    
    NETWORKS["${bssid}_bssid"]="$bssid"
    NETWORKS["${bssid}_essid"]="$essid"
    NETWORKS["${bssid}_encryption"]="$encryption"
    NETWORKS["${bssid}_signal"]="$signal"
    NETWORKS["${bssid}_channel"]="$channel"
    NETWORKS["${bssid}_last_seen"]=$(date +%s)
    
    # Add to list if not already present
    if [[ ! " ${NETWORK_LIST[@]} " =~ " ${bssid} " ]]; then
        NETWORK_LIST+=("$bssid")
    fi
}

# Get network data
get_network_data() {
    local bssid="$1"
    local field="$2"
    
    echo "${NETWORKS[${bssid}_${field}]}"
}

# Remove network
remove_network() {
    local bssid="$1"
    local i
    
    for i in "${!NETWORK_LIST[@]}"; do
        if [[ "${NETWORK_LIST[$i]}" == "$bssid" ]]; then
            unset 'NETWORK_LIST[$i]'
            break
        fi
    done
    
    unset NETWORKS["${bssid}_bssid"]
    unset NETWORKS["${bssid}_essid"]
    unset NETWORKS["${bssid}_encryption"]
    unset NETWORKS["${bssid}_signal"]
    unset NETWORKS["${bssid}_channel"]
    unset NETWORKS["${bssid}_last_seen"]
}

# Clear all networks
clear_networks() {
    NETWORK_LIST=()
    unset NETWORKS
    declare -g -A NETWORKS
}

# ============================================================================
# SORTING
# ============================================================================

# Sort networks by criteria
sort_networks() {
    local sort_by="${1:-signal}"
    local sort_order="${2:-desc}"
    
    SORT_BY="$sort_by"
    SORT_ORDER="$sort_order"
    
    local -a indices=()
    local i
    
    for i in "${!NETWORK_LIST[@]}"; do
        indices+=("$i")
    done
    
    # Bubble sort (simple for small datasets)
    local n=${#indices[@]}
    local swapped
    
    for ((i = 0; i < n - 1; i++)); do
        swapped=0
        for ((j = 0; j < n - i - 1; j++)); do
            local idx1=${indices[$j]}
            local idx2=${indices[$((j + 1))]}
            local bssid1=${NETWORK_LIST[$idx1]}
            local bssid2=${NETWORK_LIST[$idx2]}
            
            local val1 val2
            
            case "$sort_by" in
                signal)
                    val1=${NETWORKS["${bssid1}_signal"]:-0}
                    val2=${NETWORKS["${bssid2}_signal"]:-0}
                    val1=${val1%dBm}
                    val2=${val2%dBm}
                    ;;
                ssid)
                    val1=${NETWORKS["${bssid1}_essid"]}
                    val2=${NETWORKS["${bssid2}_essid"]}
                    ;;
                encryption)
                    val1=${NETWORKS["${bssid1}_encryption"]}
                    val2=${NETWORKS["${bssid2}_encryption"]}
                    ;;
                channel)
                    val1=${NETWORKS["${bssid1}_channel"]:-0}
                    val2=${NETWORKS["${bssid2}_channel"]:-0}
                    ;;
            esac
            
            # Compare values
            local compare=0
            if [[ "$sort_by" == "signal" || "$sort_by" == "channel" ]]; then
                [[ $val1 -lt $val2 ]] && compare=1
            else
                [[ "$val1" < "$val2" ]] && compare=1
            fi
            
            # Check sort order
            if { [[ "$sort_order" == "asc" && $compare -eq 1 ]] || \
                 [[ "$sort_order" == "desc" && $compare -eq 0 ]]; }; then
                # Swap
                local temp=${indices[$j]}
                indices[$j]=${indices[$((j + 1))]}
                indices[$((j + 1))]=$temp
                swapped=1
            fi
        done
        
        [[ $swapped -eq 0 ]] && break
    done
    
    # Rebuild list
    local -a new_list=()
    for idx in "${indices[@]}"; do
        new_list+=("${NETWORK_LIST[$idx]}")
    done
    NETWORK_LIST=("${new_list[@]}")
}

# ============================================================================
# FILTERING
# ============================================================================

# Get visible networks (filtered)
get_visible_networks() {
    local -a visible=()
    local bssid
    
    for bssid in "${NETWORK_LIST[@]}"; do
        if [[ -z "$FILTER_ENCRYPTION" ]]; then
            visible+=("$bssid")
        else
            local enc=${NETWORKS["${bssid}_encryption"]}
            [[ "$enc" == "$FILTER_ENCRYPTION" ]] && visible+=("$bssid")
        fi
    done
    
    printf '%s\n' "${visible[@]}"
}

# Set encryption filter
set_encryption_filter() {
    local encryption="$1"
    FILTER_ENCRYPTION="$encryption"
}

# Clear filter
clear_filter() {
    FILTER_ENCRYPTION=""
}

# ============================================================================
# SIGNAL STRENGTH INDICATORS
# ============================================================================

# Convert signal strength to visual bar
signal_to_visual() {
    local signal="$1"
    local width=10
    
    # Extract numeric value
    signal=${signal%dBm}
    signal=${signal# }
    
    # Normalize to 0-100 (typical range is -100 to -30)
    local strength=0
    if [[ $signal -le -100 ]]; then
        strength=0
    elif [[ $signal -ge -30 ]]; then
        strength=100
    else
        strength=$(( (-30 - signal) * 100 / 70 ))
        strength=$(( 100 - strength ))
    fi
    
    # Create visual bar
    local filled=$(( (strength * width) / 100 ))
    local empty=$(( width - filled ))
    
    printf "${FG_GREEN}"
    for ((i = 0; i < filled; i++)); do printf "█"; done
    printf "${FG_RED}"
    for ((i = 0; i < empty; i++)); do printf "░"; done
    printf "${COLOR_RESET}"
}

# Get signal quality level
signal_to_level() {
    local signal="$1"
    signal=${signal%dBm}
    signal=${signal# }
    
    if [[ $signal -le -100 ]]; then
        echo "Muito fraco"
    elif [[ $signal -le -70 ]]; then
        echo "Fraco"
    elif [[ $signal -le -50 ]]; then
        echo "Bom"
    elif [[ $signal -le -30 ]]; then
        echo "Excelente"
    else
        echo "Desconhecido"
    fi
}

# Get encryption color
encryption_to_color() {
    local encryption="$1"
    
    case "$encryption" in
        WEP|OPEN|"Sem Encriptação")
            echo "$FG_RED"
            ;;
        WPA)
            echo "$FG_YELLOW"
            ;;
        WPA2)
            echo "$FG_GREEN"
            ;;
        WPA3)
            echo "$FG_BLUE"
            ;;
        *)
            echo "$FG_CYAN"
            ;;
    esac
}

# ============================================================================
# DISPLAY
# ============================================================================

# Display network list table
display_network_list() {
    local height
    height=$(get_terminal_height)
    local available_lines=$(( height - 10 ))
    
    # Draw header
    draw_box "Redes WiFi Disponíveis" 80
    
    printf "│ %-2s │ %-20s │ %-15s │ %-12s │ %-8s │ %-8s │\n" \
        "#" "SSID" "BSSID" "Encriptação" "Sinal" "Canal"
    draw_line 80 "─"
    
    # Display networks
    local -a visible
    mapfile -t visible < <(get_visible_networks)
    
    local i=0
    for bssid in "${visible[@]}"; do
        if [[ $i -ge $available_lines ]]; then
            printf "│ ... │ (Total: %d redes) %*s │\n" "${#visible[@]}" 40 ""
            break
        fi
        
        local essid=${NETWORKS["${bssid}_essid"]}
        local encryption=${NETWORKS["${bssid}_encryption"]}
        local signal=${NETWORKS["${bssid}_signal"]}
        local channel=${NETWORKS["${bssid}_channel"]}
        
        # Truncate SSID if needed
        essid=$(printf "%-20s" "${essid:0:20}")
        bssid=$(printf "%-15s" "${bssid:0:15}")
        encryption=$(printf "%-12s" "${encryption:0:12}")
        signal=$(printf "%-8s" "${signal:0:8}")
        channel=$(printf "%-8s" "$channel")
        
        # Highlight selected network
        if [[ $i -eq $SELECTED_NETWORK_IDX ]]; then
            printf "${BG_BLUE}${FG_WHITE}"
        fi
        
        printf "│ %2d │ %s │ %s │ %s │ %s │ %s │\n" \
            $((i + 1)) "$essid" "$bssid" "$encryption" "$signal" "$channel"
        
        printf "${COLOR_RESET}"
        ((i++))
    done
    
    draw_line 80 "─"
}

# Display detailed network info
display_network_details() {
    local bssid="$1"
    
    if [[ -z "$bssid" ]]; then
        show_error "Network not found"
        return 1
    fi
    
    clear_screen
    render_header "Detalhes da Rede"
    
    local essid=${NETWORKS["${bssid}_essid"]}
    local encryption=${NETWORKS["${bssid}_encryption"]}
    local signal=${NETWORKS["${bssid}_signal"]}
    local channel=${NETWORKS["${bssid}_channel"]}
    local last_seen=${NETWORKS["${bssid}_last_seen"]}
    
    echo ""
    draw_box "Informações da Rede" 70
    
    printf "│ %-20s : %-40s │\n" "SSID" "$essid"
    printf "│ %-20s : %-40s │\n" "BSSID (MAC)" "$bssid"
    printf "│ %-20s : %-40s │\n" "Encriptação" "$encryption"
    printf "│ %-20s : %-40s │\n" "Força do Sinal" "$signal ($(signal_to_level "$signal"))"
    printf "│ %-20s : %-40s │\n" "Canal" "$channel"
    
    local seen_date
    seen_date=$(date -d "@$last_seen" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "N/A")
    printf "│ %-20s : %-40s │\n" "Último visto" "$seen_date"
    
    draw_box_bottom 70
    
    echo ""
    echo "$(signal_to_visual "$signal") $signal"
    echo ""
}

# ============================================================================
# SELECTION
# ============================================================================

# Get selected network
get_selected_network() {
    local -a visible
    mapfile -t visible < <(get_visible_networks)
    
    if [[ $SELECTED_NETWORK_IDX -lt ${#visible[@]} ]]; then
        echo "${visible[$SELECTED_NETWORK_IDX]}"
    fi
}

# Move selection down
select_next_network() {
    local -a visible
    mapfile -t visible < <(get_visible_networks)
    
    if [[ $SELECTED_NETWORK_IDX -lt $(( ${#visible[@]} - 1 )) ]]; then
        ((SELECTED_NETWORK_IDX++))
    fi
}

# Move selection up
select_previous_network() {
    if [[ $SELECTED_NETWORK_IDX -gt 0 ]]; then
        ((SELECTED_NETWORK_IDX--))
    fi
}

# ============================================================================
# STATISTICS
# ============================================================================

# Get network count
get_network_count() {
    echo "${#NETWORK_LIST[@]}"
}

# Get average signal strength
get_average_signal() {
    local total=0
    local count=0
    local bssid
    
    for bssid in "${NETWORK_LIST[@]}"; do
        local signal=${NETWORKS["${bssid}_signal"]}
        signal=${signal%dBm}
        signal=${signal# }
        
        if [[ -n "$signal" && "$signal" =~ ^-?[0-9]+$ ]]; then
            ((total += signal))
            ((count++))
        fi
    done
    
    if [[ $count -gt 0 ]]; then
        echo $(( total / count ))
    else
        echo "0"
    fi
}

# Export functions
export -f add_network
export -f get_network_data
export -f remove_network
export -f clear_networks
export -f sort_networks
export -f get_visible_networks
export -f set_encryption_filter
export -f clear_filter
export -f signal_to_visual
export -f signal_to_level
export -f encryption_to_color
export -f display_network_list
export -f display_network_details
export -f get_selected_network
export -f select_next_network
export -f select_previous_network
export -f get_network_count
export -f get_average_signal
