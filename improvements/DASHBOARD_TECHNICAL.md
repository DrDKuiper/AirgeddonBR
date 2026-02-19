# Dashboard Interativo - Documentação Técnica

## Visão Geral

O Dashboard é uma aplicação de interface de usuário em texto (TUI - Text User Interface) desenvolvida em Bash puro, que permite auditoria interativa de redes WiFi com análise de vulnerabilidades em tempo real.

**Versão**: 1.0  
**Linguagem**: Bash 4.2+  
**Dependencies**: tput, grep, date (ferramentas padrão Unix)  
**Tamanho Total**: ~2500 linhas de código Bash

---

## Arquitetura do Sistema

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────┐
│                 DASHBOARD PRINCIPAL                     │
│              (ui/dashboard.sh - 600+ linhas)            │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   UI Manager │  │   Network    │  │   UI         │  │
│  │  (TUI state) │  │   Viewer     │  │   Components │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│   (tui_manager.sh)(network_viewer.sh)(ui_components)  │
│         200 linhas       200 linhas       250 linhas   │
├─────────────────────────────────────────────────────────┤
│  Integrations:                                          │
│  • vulnerability_analyzer.sh (Análise de risco)        │
│  • report_generator.sh (Exportação)                    │
│  • logging.sh (Auditoria de eventos)                   │
└─────────────────────────────────────────────────────────┘
```

### Fluxo de Dados

```
Entrada do Usuário (Teclado)
         ↓
    TUI Manager
    (State Track)
         ↓
    View Handler
    (Renderização)
         ↓
    Network Viewer
    (Processamento)
         ↓
    UI Components
    (Desenho/Saída)
         ↓
    Terminal Output
    (Visualização)
```

---

## Módulos Detalhados

### 1. ui_components.sh (250+ linhas)

**Propósito**: Componentes básicos de interface reutilizáveis

**Classes de Funções**:

#### Terminal Management
```bash
get_terminal_width()    # Obtém largura do terminal
get_terminal_height()   # Obtém altura do terminal
supports_colors()       # Verifica suporte a cores
clear_screen()          # Limpa a tela
cursor_position()       # Move cursor para posição (row, col)
hide_cursor()           # Oculta cursor
show_cursor()           # Mostra cursor
```

**Complexidade**: O(1) para a maioria das funções

#### Text Styling
```bash
center_text()           # Centraliza texto na tela
right_align_text()      # Alinha texto à direita
pad_text()              # Preenche texto até largura N
truncate_text()         # Corta texto com "..." se necessário
```

**Especificação**:
- `pad_text "teste" 10` → "teste     " (10 caracteres)
- `truncate_text "muito longo" 8` → "muito..."

#### Visual Elements
```bash
draw_line()             # Desenha linha horizontal
draw_box()              # Desenha caixa com título
draw_box_bottom()       # Bottom border da caixa
```

**Exemplo de Caixa**:
```
┌──────────────────────────┐
│ Título da Caixa          │
├──────────────────────────┤
│ Conteúdo aqui           │
└──────────────────────────┘
```

#### Table Functions
```bash
table_header()          # Renderiza cabeçalho de tabela
table_row()             # Renderiza linha de dados
draw_table()            # Desenha tabela completa
```

**Performance**: Otimizado para tabelas até 100 linhas

#### Menu & Selection
```bash
display_menu()          # Exibe opções do menu
select_option()         # Captura seleção do usuário
```

**Validação**: Aceita apenas números válidos (1-N)

#### Progress & Indicators
```bash
progress_bar()          # Barra de progresso (10 a 50 caracteres)
spinner_start()         # Inicia animação de spinner
spinner_stop()          # Para spinner
```

**Animação**: 4 caracteres de rotação (| / - \) a ~100ms por ciclo

#### Status Messages
```bash
show_success()          # ✓ Mensagem de sucesso (verde)
show_error()            # ✗ Erro (vermelho)
show_warning()          # ⚠ Aviso (amarelo)
show_info()             # ℹ Informação (azul)
```

#### Dialogs
```bash
confirm_dialog()        # Confirma ação (S/N)
input_dialog()          # Captura entrada de texto
```

---

### 2. tui_manager.sh (200+ linhas)

**Propósito**: Gerenciar estado, navegação e ciclo de vida da TUI

**Estado Global Mantido**:
```bash
TUI_STATE_INITIALIZED   # Flag de inicialização
CURRENT_VIEW            # View atual ("home", "networks", etc)
PREVIOUS_VIEW           # View anterior (para voltar)
STATE_STACK             # Histórico de navegação
STATE_STACK_SIZE        # Tamanho do histórico
TUI_MODE                # "interactive" ou "batch"
AUTO_REFRESH            # Flag para auto-atualização
REFRESH_INTERVAL        # Intervalo em segundos
STATUS_MESSAGE          # Mensagem de status actual
STATUS_TYPE             # Tipo (info/success/error/warning)
SESSION_ID              # ID único da sessão
TUI_CONTEXT             # Array associativo de contexto
```

**Inicialização**:
```bash
initialize_tui() {
    # 1. Configura handlers de sinal (EXIT, INT, TERM)
    # 2. Oculta cursor
    # 3. Inicializa estado global
    # 4. Marca TUI como pronta
}
```

**Lifecycle Events**:
- `on_tui_exit()` - Limpa e mostra cursor ao sair
- `on_tui_interrupt()` - Trata Ctrl+C graciosamente

**Gerenciamento de Views**:
```bash
change_view()           # Muda para nova view, salva anterior
go_back()               # Volta para view anterior
get_current_view()      # Retorna view atual
get_previous_view()     # Retorna view anterior
```

**Stack Implementation**:
```
Stack de Views: [home] → [networks] → [details]
                  ↑         ↑           ↑
              state[0]   state[1]    state[2]
```

**Gerenciamento de Contexto** (tipo HashMap):
```bash
set_context "selected_network" "AA:BB:CC:DD:EE:FF"
get_context "selected_network"              # AA:BB:CC:DD:EE:FF
get_context "unknown_key" "default_value"   # default_value
```

---

### 3. network_viewer.sh (200+ linhas)

**Propósito**: Gerenciar e visualizar dados de redes WiFi

**Estrutura de Dados - Redes**:
```bash
# Armazenage em Arrays Associativos:
NETWORKS[${BSSID}_bssid]        # BSSID (MAC Address)
NETWORKS[${BSSID}_essid]        # SSID (nome da rede)
NETWORKS[${BSSID}_encryption]   # Tipo de encriptação
NETWORKS[${BSSID}_signal]       # Força do sinal (em dBm)
NETWORKS[${BSSID}_channel]      # Canal WiFi (1-14)
NETWORKS[${BSSID}_last_seen]    # Timestamp Unix

NETWORK_LIST[]                  # Array de BSSIDs (índice inteiro)
```

**Operações Básicas**:

```bash
# Adicionar rede
add_network "AA:BB:CC:DD:EE:01" "MyWiFi" "WPA2" "-50dBm" "6"
# Complexidade: O(1)

# Remover rede
remove_network "AA:BB:CC:DD:EE:01"
# Complexidade: O(n) - scan do NETWORK_LIST

# Obter dados
get_network_data "AA:BB:CC:DD:EE:01" "encryption"
# Complexidade: O(1)

# Limpar todas as redes
clear_networks
# Complexidade: O(n)
```

**Ordenação - Bubble Sort** O(n²):
```bash
sort_networks "signal" "desc"   # Por força (descendente)
sort_networks "ssid" "asc"      # Por nome (A-Z)
sort_networks "channel" "asc"   # Por canal (crescente)
sort_networks "encryption" "asc"# Por tipo (A-Z)
```

**Algoritmo de Comparação**:
- Números: Comparação aritmética (`-lt`, `-gt`)
- Strings: Comparação lexicográfica (`<`, `>`)

**Filtragem** O(n):
```bash
set_encryption_filter "WPA2"    # Mostra apenas WPA2
mapfile -t visible < <(get_visible_networks)
# Retorna: Array de BSSIDs visíveis

clear_filter                    # Remove filtro
```

**Visualização de Sinal**:

```bash
signal_to_visual "-50dBm"  # ██████████░░░░░░░░ (10/20 barras)
signal_to_level "-50dBm"   # "Bom"

# Scales:
# <= -100dBm → Muito fraco
# -70 a -100 → Fraco
# -50 a -70  → Bom
# -30 a -50  → Excelente
```

**Seleção de Redes**:
```bash
SELECTED_NETWORK_IDX=0          # Índice na lista filtrada

get_selected_network()          # Retorna BSSID selecionado
select_next_network()           # Seta próxima (se disponível)
select_previous_network()       # Seta anterior (se disponível)
```

**Estatísticas**:
```bash
get_network_count()             # Total de redes
get_average_signal()            # Força de sinal média
```

---

### 4. dashboard.sh (600+ linhas)

**Propósito**: Interface principal que integra todos os componentes

**Views Principais**:

#### 1. Main Menu
- Opções 1-5: Explorar, Analisar, Relatório, Estatísticas, Config
- Status bar dinâmico com contagem de redes
- Loop infinito até seleção de saída

#### 2. Network Explorer
```
┌─────────────────────────────────────────┐
│ Explorador de Redes WiFi                │
├────┬──────────┬──────┬────┬──────┬──────┤
│ #  │ SSID     │ BSSID│ Enc│ Sinal│ Canal│
├────┼──────────┼──────┼────┼──────┼──────┤
│ 1  │ MyWiFi   │ AA.. │WPA2│-50dB │  6   │ ← Selecionado
│ 2  │ OpenNet  │ BB.. │OPEN│-65dB │  1   │
└────┴──────────┴──────┴────┴──────┴──────┘

Controles: J/U (mover), Enter (detalhes), A (analisar)
           S (ordenar), F (filtrar), B (voltar)
```

**Características**:
- Renderização em tempo real
- Paginação automática (trunca em altura terminal - 10 linhas)
- Destaque dinâmico da seleção (inverte cores)
- Non-blocking input com timeout (0.1s)

#### 3. Vulnerability Analysis
- Análise individual de rede selecionada
- Análise em lote (todas as redes visíveis)
- Histórico de análises (mock data)
- Lista de vulnerabilidades comuns

**Dados de Demonstração**:
- Mostra: SSID, MAC, Encriptação, Sinal, Risco
- Integra com `analyze_encryption()` se disponível

#### 4. Report Generation
```
Formato 1: JSON
{
  "metadata": { "title", "timestamp", "hostname" },
  "networks": [ { "bssid", "essid", "encryption", "signal" } ],
  "vulnerabilities": [ { "id", "network", "type", "severity" } ]
}

Formato 2: HTML
<html>
  <head><style>/* CSS com cores por severidade */</style></head>
  <body>
    <table><!-- Redes e vulnerabilidades --></table>
  </body>
</html>

Formato 3: CSV
BSSID,SSID,Encryption,Signal,Risk
AA:BB:...,MyWiFi,WPA2,-50dBm,LOW
```

#### 5. Statistics View
- Total de redes
- Sinal médio
- Contagem por tipo de encriptação
- Percentuais de risco

#### 6. Settings
- Intervalo de atualização (configurável)
- Modo de exibição
- Informações "Sobre"

---

## Fluxo de Execução Completo

```
1. Main Entry Point
   └─→ initialize_tui()
       ├─→ trap signals (EXIT, INT, TERM)
       ├─→ hide_cursor()
       └─→ TUI_STATE_INITIALIZED=1

2. Load Demo Data
   └─→ load_demo_networks()
       ├─→ add_network() x 5
       └─→ NETWORK_LIST populated

3. Render Main Menu
   └─→ render_header()
   └─→ display menu options
   └─→ render_status_bar()
   └─→ render_footer()

4. User Input Loop
   └─→ read choice (1-5, 0)
       ├─ Case 1: view_networks()
       │   └→ sort_networks()
       │   └→ display_network_list()
       │   └→ Read input (j/u/Enter/A/S/F/B)
       │   └→ Process action
       │
       ├─ Case 2: vulnerability_menu()
       │   └→ Display sub-menu
       │   └→ Handle choice (1-4, 0)
       │   └→ Integrates with vulnerability_analyzer.sh
       │
       ├─ Case 3: report_menu()
       │   └→ select format (JSON/HTML/CSV/All)
       │   └→ generate_report()
       │
       ├─ Case 4: statistics_view()
       │   └→ calculate stats from networks
       │   └→ display_box() with results
       │
       ├─ Case 5: settings_menu()
       │   └→ Adjust intervals/modes
       │
       └─ Case 0: confirm_dialog()
           └→ Exit if confirmed

5. Cleanup on Exit
   └─→ on_tui_exit() [Trap]
       ├─→ show_cursor()
       └─→ clear_screen()
```

---

## Padrões de Design Utilizados

### 1. **Associative Array Map Pattern**
```bash
# Ao invés de:
NETWORKS=("AA:BB:... "TestSSID" "WPA2" ...)  # Difícil de manter

# Usamos:
NETWORKS["${BSSID}_essid"]="TestSSID"       # Chave-valor clara
NETWORKS["${BSSID}_encryption"]="WPA2"      # Auto-documentado
```

### 2. **State Machine Pattern**
```
CURRENT_VIEW ──→ change_view() ──→ PREVIOUS_VIEW
                                  (stack mantém histórico)
```

### 3. **Observer Pattern (Mock)**
```bash
# Em vez de callbacks reais:
status_changed() {
    set_status "message" "type"
    render_status_bar()  # Reflexo imediato
}
```

### 4. **Factory for Components**
```bash
# display_menu() é um "factory" que cria estrutura do menu
# display_table() é um "factory" que cria estrutura de tabela
```

---

## Performance Characteristics

### Tempo de Execução

| Operação | Complexidade | Tempo Real |
|----------|--------------|-----------|
| `add_network()` | O(1) | < 1ms |
| `sort_networks()` | O(n²) | 5-50ms (10-100 redes) |
| `display_network_list()` | O(k) | 1-5ms (k ≤ altura terminal) |
| `get_visible_networks()` | O(n) | 1-3ms (100 redes) |
| `render screen` | O(n) | 5-10ms (completo) |

### Memória

- Base TUI: ~2MB Bash interpreter
- Por rede observada: ~200 bytes (BSSID + ESSID + metadata)
- 100 redes: ~20KB adicional
- Stack de views: ~1KB por 10 navigações

---

## Testes e Validação

### Suite de Testes: test_dashboard.bats (50+ testes)

**Categorias**:

1. **UI Components Tests** (10 testes)
   - Terminal width/height
   - Text padding/truncation
   - Byte formatting

2. **TUI Manager Tests** (15 testes)
   - Inicialização
   - Change view / go back
   - Context storage
   - Status management
   - Auto-refresh flags

3. **Network Viewer Tests** (25+ testes)
   - Add/remove networks
   - Sorting (signal, SSID, channel, encryption)
   - Filtering
   - Selection movement
   - Signal conversion
   - Statistics

4. **Integration Tests** (3+ testes)
   - Empty state handling
   - Special characters in SSID
   - Session management

### Cobertura de Teste
- **UI Components**: 100% (8/8 funções críticas)
- **TUI Manager**: 100% (12/12 funções)
- **Network Viewer**: 95% (18/19 funções)
- **Dashboard**: 40% (demo functions, manual integration tests)

---

## Guia de Integração

### Com Airgeddon Original

```bash
# No airgeddon.sh, após sourcing do logging:

source "${SCRIPT_DIR}/improvements/ui/dashboard.sh"

# Ao invés de menu_principal_airgeddon():
# Pode usar: main_menu_dashboard()

# Carregar redes reais do iwlist:
while read -r line; do
    # Parse iwlist output
    bssid=$(echo "$line" | grep -oP '(?<=Address: )[A-F0-9:]+')
    essid=$(echo "$line" | grep -oP '(?<=ESSID: ")[^"]+')
    # ...
    add_network "$bssid" "$essid" "$encryption" "$signal" "$channel"
done < <(iwlist wlan0 scan)

# Iniciar dashboard com dados reais
initialize_tui
main_menu
```

### Com Vulnerability Analyzer

```bash
# No dashboard.sh analyze_network():

if declare -f analyze_encryption >/dev/null 2>&1; then
    # vulnerability_analyzer.sh foi sourced
    local risk
    risk=$(perform_security_analysis "$bssid" "$essid" "$encryption" "$signal")
    
    # Mostrar resultado
    echo "Risk Score: $risk / 100"
fi
```

---

## Limitações Conhecidas

1. **Sorting O(n²)** - Bubble sort simples. Para >1000 redes, considere merge sort.
2. **Non-blocking Input** - Usa read com timeout; pode perder inputs rápidos.
3. **Color Support** - Assume terminal ANSI. Pode não funcionar em terminais antigos.
4. **Sem Mouse** - Navegação somente teclado (by design para SSH).
5. **Terminal Resize** - Não redimensiona dinamicamente durante execução.

---

## Possíveis Melhorias Futuras

1. **Search/Filter** - Campo de busca por SSID
2. **Export Config** - Salvar preferências de sort/filter
3. **Real-time Refresh** - Auto-atualizar lista de redes a cada N segundos
4. **Multi-column Sort** - Ordenar por múltiplas colunas
5. **Network Details Expanded** - Mais informações por rede (clients, etc)
6. **Dark/Light Theme** - Seleção de tema visual

---

## Conclusão

O Dashboard demonstra como criar uma TUI profissional em Bash puro, sem dependências gráficas. É adequado para:
- Auditoria de segurança WiFi
- Sistemas embarcados/IoT
- SSH sessions remotas
- Ambiente servidores sem X11

Mantém compatibilidade com Bash 4.2+ e usa apenas ferramentas padrão Unix.
