#!/bin/bash

################################################################################
# Airgeddon Improvements - Dashboard Quick Start
# 
# Purpose: Interactive guide to the TUI dashboard
# Version: 1.0
#
# This script demonstrates the complete dashboard functionality with
# interactive examples and sample data.
################################################################################

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMPROVEMENTS_DIR="${SCRIPT_DIR}/.."

# Source dashboard
source "${IMPROVEMENTS_DIR}/ui/dashboard.sh"

# ============================================================================
# DEMO MODES
# ============================================================================

demo_ui_components() {
    clear_screen
    echo ""
    center_text "${COLOR_BOLD}${COLOR_CYAN}=== Demonstração: Componentes de UI ===${COLOR_RESET}"
    echo ""
    
    echo "Teste 1: Tabela de Cores"
    echo ""
    printf "  ${FG_BLACK}Preto${COLOR_RESET}  "
    printf "${FG_RED}Vermelho${COLOR_RESET}  "
    printf "${FG_GREEN}Verde${COLOR_RESET}  "
    printf "${FG_YELLOW}Amarelo${COLOR_RESET}  "
    printf "${FG_BLUE}Azul${COLOR_RESET}  "
    printf "${FG_MAGENTA}Magenta${COLOR_RESET}  "
    printf "${FG_CYAN}Ciano${COLOR_RESET}\n"
    echo ""
    
    echo "Teste 2: Caixa"
    echo ""
    draw_box "Exemplo de Caixa" 60
    echo "│ Conteúdo da caixa aqui │"
    draw_box_bottom 60
    echo ""
    
    echo "Teste 3: Progresso"
    echo ""
    for i in {1..5}; do
        progress_bar "$i" "5" 40
        sleep 0.3
    done
    echo ""
    
    echo "Teste 4: Mensagens de Status"
    echo ""
    show_success "Operação bem-sucedida"
    show_error "Erro detectado"
    show_warning "Aviso importante"
    show_info "Informação relevante"
    echo ""
    
    read -p "Pressione Enter para continuar..."
}

demo_network_viewer() {
    clear_screen
    echo ""
    center_text "${COLOR_BOLD}${COLOR_CYAN}=== Demonstração: Visualizador de Redes ===${COLOR_RESET}"
    echo ""
    
    echo "Carregando redes de demonstração..."
    load_demo_networks
    
    echo "Total de redes carregadas: $(get_network_count)"
    echo ""
    
    echo "Teste 1: Listar Redes"
    echo ""
    display_network_list
    echo ""
    
    echo "Teste 2: Ordenar por SSID"
    echo ""
    sort_networks "ssid" "asc"
    echo "Primeiras 3 redes ordenadas alfabeticamente:"
    local i=0
    for bssid in "${NETWORK_LIST[@]}"; do
        if [[ $i -ge 3 ]]; then break; fi
        printf "  %d. %s\n" $((i+1)) "$(get_network_data "$bssid" "essid")"
        ((i++))
    done
    echo ""
    
    echo "Teste 3: Filtrar por Encriptação (WPA2)"
    echo ""
    set_encryption_filter "WPA2"
    local -a visible
    mapfile -t visible < <(get_visible_networks)
    echo "Redes WPA2 encontradas: ${#visible[@]}"
    for bssid in "${visible[@]}"; do
        printf "  - %s (MAC: %s)\n" "$(get_network_data "$bssid" "essid")" "$bssid"
    done
    clear_filter
    echo ""
    
    echo "Teste 4: Sinal Médio"
    echo ""
    local avg
    avg=$(get_average_signal)
    echo "Força de sinal média: ${avg}dBm"
    echo ""
    
    read -p "Pressione Enter para continuar..."
}

demo_full_dashboard() {
    load_demo_networks
    main_menu
}

# ============================================================================
# MAIN MENU
# ============================================================================

show_welcome() {
    clear_screen
    echo ""
    center_text "${COLOR_BOLD}${COLOR_CYAN}╔═══════════════════════════════════════╗${COLOR_RESET}"
    center_text "${COLOR_BOLD}${COLOR_CYAN}║${COLOR_RESET}   ${COLOR_BOLD}Dashboard de Auditoria WiFi${COLOR_RESET}   ${COLOR_BOLD}${COLOR_CYAN}║${COLOR_RESET}"
    center_text "${COLOR_BOLD}${COLOR_CYAN}║${COLOR_RESET}        ${COLOR_BOLD}Guia de Demonstração${COLOR_RESET}       ${COLOR_BOLD}${COLOR_CYAN}║${COLOR_RESET}"
    center_text "${COLOR_BOLD}${COLOR_CYAN}╚═══════════════════════════════════════╝${COLOR_RESET}"
    echo ""
    echo "  Este script demonstra os recursos do dashboard interativo"
    echo "  para auditoria de segurança de redes WiFi."
    echo ""
}

main_menu_demo() {
    while true; do
        show_welcome
        
        echo ""
        echo "   ${FG_GREEN}1)${COLOR_RESET} Demonstração de Componentes UI"
        echo "   ${FG_GREEN}2)${COLOR_RESET} Demonstração do Visualizador de Redes"
        echo "   ${FG_GREEN}3)${COLOR_RESET} Dashboard Completo Interativo"
        echo "   ${FG_GREEN}0)${COLOR_RESET} Sair"
        echo ""
        
        read -p "$(printf '${FG_GREEN}Escolha uma opção:${COLOR_RESET} ')" choice
        
        case "$choice" in
            1)
                demo_ui_components
                ;;
            2)
                demo_network_viewer
                ;;
            3)
                demo_full_dashboard
                break
                ;;
            0)
                echo ""
                echo "Obrigado por usar o Dashboard de Auditoria WiFi!"
                echo ""
                break
                ;;
            *)
                show_error "Opção inválida"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# ENTRY POINT
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Initialize TUI
    initialize_tui "echo"
    
    # Show main menu
    main_menu_demo
    
    # Cleanup
    show_cursor
fi
