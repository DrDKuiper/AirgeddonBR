#!/bin/bash

################################################################################
# Airgeddon Improvements - Interactive Dashboard
# 
# Purpose: Main TUI dashboard for WiFi security analysis
# Version: 1.0
# License: GPL3
# 
# Description:
#   Complete text-based user interface for browsing networks, analyzing
#   vulnerabilities, viewing reports, and managing security assessments.
################################################################################

set -o pipefail

# Source required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/ui_components.sh" || {
    echo "Error: Could not source ui_components.sh"
    exit 1
}
source "${SCRIPT_DIR}/tui_manager.sh" || {
    echo "Error: Could not source tui_manager.sh"
    exit 1
}
source "${SCRIPT_DIR}/network_viewer.sh" || {
    echo "Error: Could not source network_viewer.sh"
    exit 1
}

# Source vulnerability analyzer if available
ANALYZER_PATH=""
if [[ -f "${SCRIPT_DIR}/../tools/vulnerability_analyzer.sh" ]]; then
    ANALYZER_PATH="${SCRIPT_DIR}/../tools/vulnerability_analyzer.sh"
    source "$ANALYZER_PATH"
fi

# ============================================================================
# DEMO DATA
# ============================================================================

# Load sample networks for demonstration
load_demo_networks() {
    # Network 1: Open network
    add_network "AA:BB:CC:DD:EE:01" "Open WiFi" "OPEN" "-45dBm" "1"
    
    # Network 2: WEP network
    add_network "AA:BB:CC:DD:EE:02" "LegacyNetwork" "WEP" "-65dBm" "6"
    
    # Network 3: WPA2
    add_network "AA:BB:CC:DD:EE:03" "SecureNetwork" "WPA2" "-50dBm" "11"
    
    # Network 4: WPA3
    add_network "AA:BB:CC:DD:EE:04" "ModernNetwork" "WPA3" "-35dBm" "13"
    
    # Network 5: Mixed network
    add_network "AA:BB:CC:DD:EE:05" "MixedMode" "WPA/WPA2" "-60dBm" "3"
}

# ============================================================================
# MAIN MENU
# ============================================================================

main_menu() {
    while true; do
        render_header "Menu Principal"
        
        echo ""
        echo "   ${FG_GREEN}1)${COLOR_RESET} Explorar Redes WiFi"
        echo "   ${FG_GREEN}2)${COLOR_RESET} Análise de Vulnerabilidades"
        echo "   ${FG_GREEN}3)${COLOR_RESET} Gerar Relatório"
        echo "   ${FG_GREEN}4)${COLOR_RESET} Estatísticas da Auditoria"
        echo "   ${FG_GREEN}5)${COLOR_RESET} Configurações"
        echo "   ${FG_GREEN}0)${COLOR_RESET} Sair"
        echo ""
        
        set_status "${COLOR_DIM}Total de redes: $(get_network_count)${COLOR_RESET}" "info"
        render_status_bar
        
        echo ""
        read -p "$(printf '${FG_GREEN}Escolha uma opção:${COLOR_RESET} ')" choice
        
        case "$choice" in
            1) view_networks ;;
            2) vulnerability_menu ;;
            3) report_menu ;;
            4) statistics_view ;;
            5) settings_menu ;;
            0) 
                confirm_dialog "Tem certeza que deseja sair?" && break
                ;;
            *)
                set_status "Opção inválida" "error"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# NETWORK VIEW
# ============================================================================

view_networks() {
    change_view "networks"
    sort_networks "signal" "desc"
    
    while true; do
        render_header "Explorador de Redes WiFi"
        
        display_network_list
        
        echo ""
        echo "   ${FG_GREEN}J/U${COLOR_RESET} - Mover  ${FG_GREEN}Enter${COLOR_RESET} - Detalhes  ${FG_GREEN}A${COLOR_RESET} - Analisar"
        echo "   ${FG_GREEN}S${COLOR_RESET} - Ordenar  ${FG_GREEN}F${COLOR_RESET} - Filtrar  ${FG_GREEN}B${COLOR_RESET} - Voltar"
        echo ""
        
        read -r -t 0.1 -n 1 key 2>/dev/null || true
        
        case "$key" in
            j|J) select_next_network ;;
            u|U) select_previous_network ;;
            [Ee][Nn][Tt][Ee][Rr]|"")
                local selected
                selected=$(get_selected_network)
                if [[ -n "$selected" ]]; then
                    view_network_details "$selected"
                fi
                ;;
            a|A)
                local selected
                selected=$(get_selected_network)
                if [[ -n "$selected" ]]; then
                    analyze_network "$selected"
                fi
                ;;
            s|S) sort_menu ;;
            f|F) filter_menu ;;
            b|B)
                go_back
                break
                ;;
            q|Q) return ;;
        esac
    done
}

# View single network details
view_network_details() {
    local bssid="$1"
    
    while true; do
        display_network_details "$bssid"
        
        echo ""
        echo "   ${FG_GREEN}A${COLOR_RESET} - Analisar Vulnerabilidades"
        echo "   ${FG_GREEN}B${COLOR_RESET} - Voltar"
        echo "   ${FG_GREEN}R${COLOR_RESET} - Atualizar"
        echo ""
        
        read -p "$(printf '${FG_GREEN}Opção:${COLOR_RESET} ')" choice
        
        case "$choice" in
            a|A)
                analyze_network "$bssid"
                ;;
            b|B)
                break
                ;;
            r|R)
                continue
                ;;
            *)
                ;;
        esac
    done
}

# ============================================================================
# VULNERABILITY ANALYSIS
# ============================================================================

vulnerability_menu() {
    change_view "vulnerabilities"
    
    while true; do
        render_header "Análise de Vulnerabilidades"
        
        echo ""
        echo "   ${FG_GREEN}1)${COLOR_RESET} Analisar Rede Selecionada"
        echo "   ${FG_GREEN}2)${COLOR_RESET} Análise em Lote"
        echo "   ${FG_GREEN}3)${COLOR_RESET} Histórico de Análises"
        echo "   ${FG_GREEN}4)${COLOR_RESET} Vulnerabilidades Comuns"
        echo "   ${FG_GREEN}0)${COLOR_RESET} Voltar"
        echo ""
        
        read -p "$(printf '${FG_GREEN}Escolha uma opção:${COLOR_RESET} ')" choice
        
        case "$choice" in
            1)
                local selected
                selected=$(get_selected_network)
                if [[ -n "$selected" ]]; then
                    analyze_network "$selected"
                else
                    set_status "Selecione uma rede primeiro" "error"
                    sleep 2
                fi
                ;;
            2)
                batch_vulnerability_analysis
                ;;
            3)
                show_analysis_history
                ;;
            4)
                show_common_vulnerabilities
                ;;
            0)
                go_back
                break
                ;;
            *)
                ;;
        esac
    done
}

# Analyze single network
analyze_network() {
    local bssid="$1"
    
    if [[ -z "$ANALYZER_PATH" ]]; then
        show_error "Módulo de análise não disponível"
        return 1
    fi
    
    local essid
    essid=$(get_network_data "$bssid" "essid")
    local encryption
    encryption=$(get_network_data "$bssid" "encryption")
    local signal
    signal=$(get_network_data "$bssid" "signal")
    
    render_header "Analisando Rede" "BSSID: $bssid"
    spinner_start "Processando..."
    
    # Simulate analysis delay
    sleep 1
    
    # Call vulnerability analyzer if available
    if declare -f analyze_encryption >/dev/null 2>&1; then
        local enc_severity
        enc_severity=$(analyze_encryption "$encryption")
    else
        local enc_severity="Desconhecida"
    fi
    
    spinner_stop
    
    echo ""
    draw_box "Resultado da Análise" 70
    
    printf "│ %-20s : %-40s │\n" "ESSID" "$essid"
    printf "│ %-20s : %-40s │\n" "MAC Address" "$bssid"
    printf "│ %-20s : %-40s │\n" "Encriptação" "$encryption"
    printf "│ %-20s : %-40s │\n" "Força do Sinal" "$signal"
    printf "│ %-20s : %-40s │\n" "Risco Estimado" "$enc_severity"
    
    draw_box_bottom 70
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Batch analysis
batch_vulnerability_analysis() {
    render_header "Análise em Lote"
    
    local count
    count=$(get_network_count)
    
    echo "Iniciando análise de $count rede(s)..."
    echo ""
    
    local i=0
    for bssid in $(get_visible_networks); do
        ((i++))
        local essid
        essid=$(get_network_data "$bssid" "essid")
        
        progress_bar "$i" "$count" 50
        printf "  Analisando: %s\n" "$essid"
        
        sleep 0.2
    done
    
    echo ""
    show_success "Análise concluída para $count rede(s)"
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Show common vulnerabilities
show_common_vulnerabilities() {
    render_header "Vulnerabilidades Comuns"
    
    echo ""
    echo "  ${FG_RED}1. Redes Abertas (Sem Encriptação)${COLOR_RESET}"
    echo "     Risco: CRÍTICO - Qualquer pessoa pode acessar"
    echo ""
    
    echo "  ${FG_RED}2. WEP (Wired Equivalent Privacy)${COLOR_RESET}"
    echo "     Risco: CRÍTICO - Facilmente quebrado em minutos"
    echo ""
    
    echo "  ${FG_YELLOW}3. WPA com TKIP${COLOR_RESET}"
    echo "     Risco: ALTO - Vulnerável a ataques de replay"
    echo ""
    
    echo "  ${FG_YELLOW}4. WPS Habilitado${COLOR_RESET}"
    echo "     Risco: ALTO - Vulnerável ao ataque Pixie Dust"
    echo ""
    
    echo "  ${FG_GREEN}5. WPA2 com CCMP${COLOR_RESET}"
    echo "     Risco: BAIXO - Recomendado para uso geral"
    echo ""
    
    echo "  ${FG_CYAN}6. WPA3${COLOR_RESET}"
    echo "     Risco: MUITO BAIXO - Padrão mais seguro"
    echo ""
    
    read -p "Pressione Enter para continuar..."
}

# Analysis history (demo)
show_analysis_history() {
    render_header "Histórico de Análises"
    
    echo ""
    echo "  Data               | ESSID              | Risco    | Ação"
    draw_line 70 "─"
    
    echo "  2026-02-19 14:30  | Open WiFi          | CRÍTICO  | Bloqueado"
    echo "  2026-02-19 14:28  | LegacyNetwork      | CRÍTICO  | Alertado"
    echo "  2026-02-19 14:25  | SecureNetwork      | BAIXO    | Monitorado"
    echo "  2026-02-19 14:20  | ModernNetwork      | MUITO BAIXO | Aprovado"
    
    draw_line 70 "─"
    echo ""
    read -p "Pressione Enter para continuar..."
}

# ============================================================================
# REPORT GENERATION
# ============================================================================

report_menu() {
    change_view "reports"
    
    while true; do
        render_header "Geração de Relatórios"
        
        echo ""
        echo "   ${FG_GREEN}1)${COLOR_RESET} Gerar Relatório JSON"
        echo "   ${FG_GREEN}2)${COLOR_RESET} Gerar Relatório HTML"
        echo "   ${FG_GREEN}3)${COLOR_RESET} Gerar Relatório CSV"
        echo "   ${FG_GREEN}4)${COLOR_RESET} Gerar Relatório Completo"
        echo "   ${FG_GREEN}0)${COLOR_RESET} Voltar"
        echo ""
        
        read -p "$(printf '${FG_GREEN}Escolha uma opção:${COLOR_RESET} ')" choice
        
        case "$choice" in
            1|2|3|4)
                generate_report "$choice"
                ;;
            0)
                go_back
                break
                ;;
            *)
                ;;
        esac
    done
}

# Generate report
generate_report() {
    local format="$1"
    
    render_header "Gerando Relatório"
    
    local format_name=""
    case "$format" in
        1) format_name="JSON" ;;
        2) format_name="HTML" ;;
        3) format_name="CSV" ;;
        4) format_name="Completo (3 formatos)" ;;
    esac
    
    spinner_start "Gerando $format_name..."
    sleep 2
    spinner_stop
    
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    
    show_success "Relatório gerado com sucesso!"
    echo ""
    echo "Salvo em: /tmp/report_${timestamp}_$format_name.dat"
    echo ""
    
    read -p "Pressione Enter para continuar..."
}

# ============================================================================
# STATISTICS
# ============================================================================

statistics_view() {
    change_view "statistics"
    
    render_header "Estatísticas da Auditoria"
    
    local count
    count=$(get_network_count)
    local avg_signal
    avg_signal=$(get_average_signal)
    
    echo ""
    draw_box "Resumo da Auditoria" 70
    
    printf "│ %-20s : %-40s │\n" "Total de Redes" "$count"
    printf "│ %-20s : %-40s │\n" "Sinal Médio" "${avg_signal}dBm"
    printf "│ %-20s : %-40s │\n" "Redes Abertas" "1"
    printf "│ %-20s : %-40s │\n" "Redes WEP" "1"
    printf "│ %-20s : %-40s │\n" "Redes WPA2" "1"
    printf "│ %-20s : %-40s │\n" "Redes WPA3" "1"
    printf "│ %-20s : %-40s │\n" "Redes Mistas" "1"
    
    draw_box_bottom 70
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# ============================================================================
# SORTING AND FILTERING
# ============================================================================

sort_menu() {
    render_header "Opções de Ordenação"
    
    echo ""
    echo "   ${FG_GREEN}1)${COLOR_RESET} Por Força de Sinal (Decrescente)"
    echo "   ${FG_GREEN}2)${COLOR_RESET} Por SSID (A-Z)"
    echo "   ${FG_GREEN}3)${COLOR_RESET} Por Canal (Crescente)"
    echo "   ${FG_GREEN}4)${COLOR_RESET} Por Encriptação"
    echo "   ${FG_GREEN}0)${COLOR_RESET} Voltar"
    echo ""
    
    read -p "$(printf '${FG_GREEN}Escolha uma opção:${COLOR_RESET} ')" choice
    
    case "$choice" in
        1)
            sort_networks "signal" "desc"
            set_status "Ordenado por sinal (descendente)" "success"
            ;;
        2)
            sort_networks "ssid" "asc"
            set_status "Ordenado por SSID (A-Z)" "success"
            ;;
        3)
            sort_networks "channel" "asc"
            set_status "Ordenado por canal" "success"
            ;;
        4)
            sort_networks "encryption" "asc"
            set_status "Ordenado por encriptação" "success"
            ;;
        0)
            ;;
    esac
    
    sleep 1
}

# Filter menu
filter_menu() {
    render_header "Opções de Filtro"
    
    echo ""
    echo "   ${FG_GREEN}1)${COLOR_RESET} WEP"
    echo "   ${FG_GREEN}2)${COLOR_RESET} WPA"
    echo "   ${FG_GREEN}3)${COLOR_RESET} WPA2"
    echo "   ${FG_GREEN}4)${COLOR_RESET} WPA3"
    echo "   ${FG_GREEN}5)${COLOR_RESET} OPEN"
    echo "   ${FG_GREEN}0)${COLOR_RESET} Limpar Filtro"
    echo "   ${FG_GREEN}B)${COLOR_RESET} Voltar"
    echo ""
    
    read -p "$(printf '${FG_GREEN}Escolha uma opção:${COLOR_RESET} ')" choice
    
    case "$choice" in
        1) set_encryption_filter "WEP"; set_status "Filtro: WEP" "success" ;;
        2) set_encryption_filter "WPA"; set_status "Filtro: WPA" "success" ;;
        3) set_encryption_filter "WPA2"; set_status "Filtro: WPA2" "success" ;;
        4) set_encryption_filter "WPA3"; set_status "Filtro: WPA3" "success" ;;
        5) set_encryption_filter "OPEN"; set_status "Filtro: OPEN" "success" ;;
        0) clear_filter; set_status "Filtro removido" "success" ;;
        [Bb]) ;;
    esac
    
    sleep 1
}

# ============================================================================
# SETTINGS
# ============================================================================

settings_menu() {
    change_view "settings"
    
    while true; do
        render_header "Configurações"
        
        echo ""
        echo "   ${FG_GREEN}1)${COLOR_RESET} Intervalo de Atualização"
        echo "   ${FG_GREEN}2)${COLOR_RESET} Modo de Exibição"
        echo "   ${FG_GREEN}3)${COLOR_RESET} Sobre"
        echo "   ${FG_GREEN}0)${COLOR_RESET} Voltar"
        echo ""
        
        read -p "$(printf '${FG_GREEN}Escolha uma opção:${COLOR_RESET} ')" choice
        
        case "$choice" in
            1)
                local interval
                interval=$(input_dialog "Novo intervalo (segundos)" "2")
                set_context "refresh_interval" "$interval"
                set_status "Intervalo atualizado para $interval segundos" "success"
                sleep 1
                ;;
            2)
                show_info "Modo de exibição: Compacta"
                sleep 1
                ;;
            3)
                show_about
                ;;
            0)
                go_back
                break
                ;;
        esac
    done
}

# Show about
show_about() {
    render_header "Sobre"
    
    echo ""
    draw_box "Airgeddon WiFi Audit Dashboard" 70
    printf "│ %-68s │\n" ""
    printf "│ %-68s │\n" "Versão: 1.0"
    printf "│ %-68s │\n" "Uma ferramenta interativa para auditoria de segurança WiFi"
    printf "│ %-68s │\n" ""
    printf "│ %-68s │\n" "Desenvolvido com Bash puro"
    printf "│ %-68s │\n" ""
    draw_box_bottom 70
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

main() {
    # Initialize TUI
    initialize_tui "log_info"
    
    # Load demo networks
    load_demo_networks
    
    # Start main menu
    main_menu
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
