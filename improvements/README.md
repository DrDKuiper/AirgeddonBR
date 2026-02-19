# 🔒 Airgeddon Improvements - Módulos de Análise Avançada

## 📋 Visão Geral

Este diretório contém os novos módulos de melhoria implementados para o Airgeddon:

- **Dashboard Interativo em TUI** - Interface gráfica de texto para análise de redes
- **Sistema de Logging Estruturado**
- **Gerador de Relatórios (JSON/HTML/CSV)**
- **Analisador de Vulnerabilidades**
- **Framework de Testes Automatizados (BATS)**

## 🗂️ Estrutura de Arquivos

```
improvements/
├── core/
│   └── logging.sh              # Sistema de logging avançado
├── tools/
│   ├── report_generator.sh     # Gerador de relatórios
│   └── vulnerability_analyzer.sh # Analisador de vulnerabilidades
├── ui/
│   ├── dashboard.sh            # Dashboard principal interativo
│   ├── ui_components.sh        # Componentes de interface (tabelas, menus)
│   ├── tui_manager.sh          # Gerenciamento de estado da TUI
│   └── network_viewer.sh       # Visualizador de redes WiFi
├── tests/
│   ├── test_logging.bats       # Testes do sistema de logging
│   ├── test_vulnerability_analyzer.bats  # Testes do analisador
│   └── test_dashboard.bats     # Testes do dashboard
├── demo.sh                      # Script de demonstração (legacy)
├── demo_dashboard.sh           # Demonstração interativa do dashboard
└── README.md                    # Este arquivo
```

---

## 🚀 Início Rápido

### 1. Instalação de Dependências

```bash
# Instalar BATS (Bash Automated Testing System)
# Ubuntu/Debian
sudo apt-get install bats

# macOS
brew install bats-core

# Ou clone do GitHub
git clone https://github.com/bats-core/bats-core.git
cd bats-core && sudo ./install.sh /usr/local
```

### 2. Executar Dashboard Interativo

```bash
chmod +x improvements/demo_dashboard.sh
improvements/demo_dashboard.sh
```

Ou diretamente o dashboard completo:

```bash
chmod +x improvements/ui/dashboard.sh
improvements/ui/dashboard.sh
```

---

## 🎨 Dashboard Interativo (TUI)

O Dashboard é uma interface de texto completa para auditoria de redes WiFi com recursos interativos.

### Recursos Principais

- ✅ **Explorador de Redes** - Listar, filtrar e ordenar redes WiFi descobertas
- ✅ **Análise de Vulnerabilidades** - Análise individual e em lote de redes
- ✅ **Geração de Relatórios** - Exportar em JSON, HTML ou CSV
- ✅ **Visualização em Tempo Real** - Estatísticas e indicadores de segurança
- ✅ **Interface Intuitiva** - Menu-driven com teclado intuitivo
- ✅ **Gerenciamento de Estado** - Rastreamento de histórico de navegação

### Componentes da TUI

#### 1. **ui_components.sh**
Fornece componentes básicos de interface:
- Caixas e linhas com bordas Unicode
- Tabelas formatadas
- Menus interativos
- Barras de progresso e spinners
- Mensagens de status (sucesso, erro, aviso, info)
- Cálculos de terminal (largura, altura)
- Funções de formatação e truncamento

#### 2. **tui_manager.sh**
Gerencia o estado da aplicação:
- Inicialização e limpeza de TUI
- Gerenciamento de views/navegação
- Auto-refresh e modo de exibição
- Armazenamento de contexto
- Gerenciamento de sessão

#### 3. **network_viewer.sh**
Visualiza e gerencia redes WiFi:
- Adicionar, remover e listar redes
- Ordenação (sinal, SSID, canal, encriptação)
- Filtragem por tipo de encriptação
- Indicadores visuais de força de sinal
- Detalhes de rede individualmente

#### 4. **dashboard.sh**
Interface principal com múltiplas views:
- Explorador de Redes WiFi
- Menu de Análise de Vulnerabilidades
- Gerador de Relatórios
- Visualização de Estatísticas
- Configurações Application

### Navegação no Dashboard

```
Menu Principal
├── Explorar Redes WiFi
│   ├── J/U - Mover seleção
│   ├── Enter - Ver detalhes
│   ├── A - Analisar vulnerabilidades
│   ├── S - Ordenar redes
│   ├── F - Filtrar por encriptação
│   └── B - Voltar
├── Análise de Vulnerabilidades
│   ├── Analisar Rede Selecionada
│   ├── Análise em Lote
│   ├── Histórico de Análises
│   └── Vulnerabilidades Comuns
├── Gerar Relatório
│   ├── JSON
│   ├── HTML
│   ├── CSV
│   └── Completo (3 formatos)
├── Estatísticas
│   └── Resumo de auditoria
└── Configurações
    ├── Intervalo de atualização
    ├── Modo de exibição
    └── Sobre
```

### Exemplo de Uso

```bash
#!/usr/bin/env bash

# Source o dashboard
source improvements/ui/dashboard.sh

# Adicionar redes manualmente
add_network "AA:BB:CC:DD:EE:01" "MyNetwork" "WPA2" "-50dBm" "6"
add_network "AA:BB:CC:DD:EE:02" "OpenWiFi" "OPEN" "-65dBm" "1"
add_network "AA:BB:CC:DD:EE:03" "LegacyNet" "WEP" "-45dBm" "11"

# Inicializar e exibir interface
initialize_tui
render_header "Auditoria de WiFi"
display_network_list

# Ordenar por sinal
sort_networks "signal" "desc"

# Filtrar por WPA2
set_encryption_filter "WPA2"
local -a visible
mapfile -t visible < <(get_visible_networks)
echo "Redes WPA2: ${#visible[@]}"
```

### Testes do Dashboard

```bash
# Rodar testes automatizados
cd improvements
bats tests/test_dashboard.bats

# Rodar com verbosidade aumentada
bats tests/test_dashboard.bats -v 

# Rodar teste específico
bats tests/test_dashboard.bats --filter "add_network creates new network entry"
```

---

## 📚 Documentação dos Módulos

### 1. Sistema de Logging (`core/logging.sh`)

O sistema de logging fornece uma interface unificada para registrar eventos com diferentes níveis de severidade.

#### Recursos Principais

- ✅ 5 níveis de log: DEBUG, INFO, WARN, ERROR, CRITICAL
- ✅ Timestamps automáticos
- ✅ Cores para saída no console
- ✅ Múltiplos arquivos de log (main, audit, error)
- ✅ Controle dinâmico de nível de log
- ✅ Suporte a logging de comandos

#### Uso Básico

```bash
#!/usr/bin/env bash
source improvements/core/logging.sh

# Log messages
log_debug "Debug information"
log_info "Operation completed"
log_warn "Something unexpected happened"
log_error "Operation failed"
log_critical "System critical failure"

# Log command execution
log_command_execution "Description" "command --args"

# Function tracing
log_function_entry "my_function"
log_function_exit "my_function" $?

# Gerenciar níveis
set_log_level "DEBUG"
get_log_level

# Limpar logs
clear_logs "all"          # Limpa tudo
clear_logs "main"         # Apenas main log
clear_logs "error"        # Apenas error log

# Ver estatísticas
get_log_stats
```

#### Configuração Avançada

```bash
# Customizar caminhos de log
export LOG_FILE="/custom/path/main.log"
export AUDIT_LOG="/custom/path/audit.log"
export ERROR_LOG="/custom/path/error.log"

# Desabilitar timestamps
export ENABLE_TIMESTAMPS="false"

# Desabilitar cores
export ENABLE_COLORS="false"

# Apenas file logging (sem console)
export ENABLE_CONSOLE_LOG="false"

# Apenas console (sem arquivo)
export ENABLE_FILE_LOG="false"

# Inicializar sistema
initialize_logging
```

#### Estrutura de Logs

**Log Principal** (`.airgeddon_logs.txt`):
```
[2025-02-19 14:30:45] [INFO] [main] Logging system initialized
[2025-02-19 14:30:46] [DEBUG] [analyze_encryption] Calculating encryption score
[2025-02-19 14:30:47] [WARN] [check_wps] WPS enabled on BSSID AA:BB:CC:DD:EE:FF
```

**Audit Log** (`.airgeddon_audit.log`):
```
[AUDIT] [2025-02-19 14:30:47] [WARN] [check_wps] WPS enabled on BSSID AA:BB:CC:DD:EE:FF
```

**Error Log** (`.airgeddon_error.log`):
```
[2025-02-19 14:30:48] [ERROR] [validate_encryption] Failed to validate encryption type
```

---

### 2. Analisador de Vulnerabilidades (`tools/vulnerability_analyzer.sh`)

Realiza análise de segurança abrangente de redes WiFi.

#### Recursos Principais

- 🔍 Análise de criptografia
- 📊 Avaliação de força de senha
- 📡 Análise de força de sinal
- 🎯 Verificação de vulnerabilidades conhecidas
- 📈 Cálculo automático de score de risco (0-100)
- 💡 Geração de recomendações de segurança

#### Funções Disponíveis

```bash
source improvements/tools/vulnerability_analyzer.sh

# Analisar criptografia (retorna: CRITICAL|HIGH|MEDIUM|LOW|NONE)
analyze_encryption "WPA2"

# Avaliar força de senha
assess_password_strength "MyPassword123!!!"

# Analisar força de sinal
analyze_signal_strength "-45"  # Excelente
analyze_signal_strength "-80"  # Fraco

# Verificar dispositivos vulneráveis conhecidos
check_device_vulnerability "88:51:FB:AA:BB:CC"

# Calcular score de risco (0-100)
calculate_risk_score "AA:BB:CC:DD:EE:FF" "WEP" "-50" "yes" "no"

# Verificar vulnerabilidades comuns
check_common_vulnerabilities '{"essid":"TestNet","encryption":"WEP"}'

# Gerar recomendações
generate_recommendations "AA:BB:CC:DD:EE:FF"

# Análise de segurança completa
perform_security_analysis "AA:BB:CC:DD:EE:FF" "MyNetwork" "WPA2" "-50"
```

#### Mapeamento de Severidade

| Severidade | Descrição |
|-----------|-----------|
| CRITICAL | Risco imediato (WEP, Aberta, etc) |
| HIGH | Vulnerabilidade significativa (WPA-TKIP) |
| MEDIUM | Risco moderado (WPA fraco) |
| LOW | Risco menor (WPA2, WPA3) |
| NONE | Seguro (WPA3) |

#### Scores de Risco

- **0-25**: Risco Baixo ✅
- **26-50**: Risco Médio ⚠️
- **51-75**: Risco Alto 🔴
- **76-100**: Risco Crítico 🚨

---

### 3. Gerador de Relatórios (`tools/report_generator.sh`)

Gera relatórios de segurança em múltiplos formatos.

#### Recursos Principais

- 📄 Exportação em JSON
- 🌐 Exportação em HTML (com CSS responsivo)
- 📊 Exportação em CSV
- 🎨 Interface visual profissional
- 📈 Estatísticas automatizadas

#### Uso

```bash
source improvements/tools/report_generator.sh

# Inicializar relatório
initialize_report "Auditoria WiFi - Fevereiro 2025"

# Adicionar redes
add_network_to_report "AA:BB:CC:DD:EE:01" "MyNetwork" "WPA2" "-45" "6"

# Adicionar vulnerabilidades
add_vulnerability "AA:BB:CC:DD:EE:01" "WPS_ENABLED" "HIGH" \
  "WPS está habilitado" "Desabilite o WPS nas configurações do roteador"

# Gerar relatórios
generate_json_report "/tmp/report.json"
generate_html_report "/tmp/report.html"
generate_csv_report "/tmp/networks.csv"

# Ver resumo
display_report_summary
```

#### Formato de Saída JSON

```json
{
  "metadata": {
    "title": "Auditoria WiFi - Fevereiro 2025",
    "timestamp": "2025-02-19T14:30:45Z",
    "hostname": "attacker-machine",
    "user": "admin",
    "tool": "Airgeddon Report Generator",
    "version": "1.0"
  },
  "networks": [
    {
      "bssid": "AA:BB:CC:DD:EE:01",
      "essid": "MyNetwork",
      "encryption": "WPA2",
      "signal_strength": -45,
      "channel": 6,
      "timestamp": "2025-02-19T14:30:45Z"
    }
  ],
  "vulnerabilities": [
    {
      "bssid": "AA:BB:CC:DD:EE:01",
      "type": "WPS_ENABLED",
      "severity": "HIGH",
      "description": "WPS está habilitado",
      "recommendation": "Desabilite o WPS",
      "timestamp": "2025-02-19T14:30:46Z"
    }
  ],
  "statistics": {
    "total_networks": 1,
    "total_vulnerabilities": 1
  }
}
```

---

## 🧪 Testes Automatizados

### Executar Testes

```bash
# Todos os testes
bats improvements/tests/test_*.bats

# Testes específicos
bats improvements/tests/test_logging.bats
bats improvements/tests/test_vulnerability_analyzer.bats

# Com relatório detalhado
bats -p improvements/tests/test_logging.bats

# Verbose mode
bats -v improvements/tests/test_logging.bats
```

### Cobertura de Testes

#### test_logging.bats
- ✅ 30+ testes
- Cobre: inicialização, logging, níveis, gerenciamento, edge cases

#### test_vulnerability_analyzer.bats
- ✅ 35+ testes
- Cobre: análise de criptografia, passwords, dispositivos, risco, vulnerabilidades

### Exemplo de Teste

```bats
@test "analyze_encryption identifies WEP as CRITICAL" {
    result=$(analyze_encryption "WEP")
    [ "${result}" = "CRITICAL" ]
}

@test "calculate_risk_score returns numeric value" {
    score=$(calculate_risk_score "AA:BB:CC:DD:EE:FF" "WPA2" "-50" "no" "no")
    [[ "${score}" =~ ^[0-9]+$ ]]
}
```

---

## 📊 Exemplos de Uso Integrado

### Exemplo 1: Análise Básica

```bash
#!/usr/bin/env bash

source improvements/core/logging.sh
source improvements/tools/vulnerability_analyzer.sh
source improvements/tools/report_generator.sh

# Iniciar
initialize_logging
initialize_report "Análise Rápida"

# Analisar rede
bssid="AA:BB:CC:DD:EE:FF"
encryption="WEP"
signal="-50"

log_info "Analisando: ${bssid}"
score=$(calculate_risk_score "${bssid}" "${encryption}" "${signal}" "no" "no")
log_info "Score de Risco: ${score}/100"

# Gerar relatório
add_network_to_report "${bssid}" "TestNet" "${encryption}" "-50" "6"
generate_json_report "report.json"
```

### Exemplo 2: Análise em Lote

```bash
#!/usr/bin/env bash

source improvements/core/logging.sh
source improvements/tools/vulnerability_analyzer.sh

initialize_logging
set_log_level "INFO"

# Array de redes
networks=(
    "AA:BB:CC:DD:EE:01|OpenNet|Open"
    "88:51:FB:AA:BB:CC|TPLink|WPA2"
    "AA:BB:CC:DD:EE:03|SecureNet|WPA3"
)

for network in "${networks[@]}"; do
    IFS='|' read -r bssid essid encryption <<< "${network}"
    
    log_info "Processando: ${essid}"
    
    # Analisar
    enc_severity=$(analyze_encryption "${encryption}")
    risk=$(calculate_risk_score "${bssid}" "${encryption}" "-50" "no" "no")
    
    log_info "  - Criptografia: ${enc_severity}"
    log_info "  - Risco: ${risk}/100"
done

get_log_stats
```

---

## 🔧 Integração com Airgeddon Original

Para integrar estas melhorias ao airgeddon.sh original:

1. **Copiar módulos:**
   ```bash
   cp improvements/core/*.sh /path/to/airgeddon/core/
   cp improvements/tools/*.sh /path/to/airgeddon/tools/
   ```

2. **Adicionar ao início do airgeddon.sh:**
   ```bash
   source "${scriptfolder}core/logging.sh"
   source "${scriptfolder}tools/vulnerability_analyzer.sh"
   source "${scriptfolder}tools/report_generator.sh"
   
   # Inicializar logging
   initialize_logging
   ```

3. **Usar ao longo do código:**
   ```bash
   # Em vez de echo simples
   log_info "Iniciando scan de redes..."
   
   # Em vez de outputs sem estrutura
   analyze_encryption "${enc_type}"
   add_vulnerability "${bssid}" "TYPE" "SEVERITY" "DESC" "REC"
   ```

---

## 📈 Performance e Otimizações

### Impacto de Performance

- **Logging**: ~1-2ms por mensagem
- **Análise de Vulnerabilidades**: ~5-10ms por rede
- **Geração de Relatório**: ~50-100ms para 100 redes

### Otimizações Recomendadas

```bash
# Desabilitar arquivo de log em operações críticas
export ENABLE_FILE_LOG="false"

# Aumentar nível de log em produção
set_log_level "ERROR"

# Cache de resultados de análise
declare -A analysis_cache
```

---

## 🐛 Troubleshooting

### Problema: BATS não encontrado
**Solução:**
```bash
# Instalar BATS
apt-get install bats  # ou brew install bats-core
```

### Problema: Permissões negadas
**Solução:**
```bash
chmod +x improvements/demo.sh
chmod +x improvements/core/*.sh
chmod +x improvements/tools/*.sh
```

### Problema: ENABLE_FILE_LOG não funciona
**Solução:**
Certifique-se de definir variáveis antes de sourcing:
```bash
export ENABLE_FILE_LOG="false"
source improvements/core/logging.sh  # APÓS exportar
```

---

## 📝 Padrões de Código

### Adicionar Nova Funcionalidade

```bash
# Sempre documentar com ShellDoc
#
# @description Descrição da função
# @arg $1 Primeiro argumento
# @return Valor de retorno
# @example example_usage
#
function my_new_function() {
    log_function_entry "${FUNCNAME[0]}"
    
    # Sua lógica aqui
    local result=$?
    
    log_function_exit "${FUNCNAME[0]}" "${result}"
    return ${result}
}
```

### Adicionar Novo Teste

```bats
@test "descrição do teste" {
    # Setup
    resultado=$(funcao_a_testar "param")
    
    # Assert
    [ "${resultado}" = "valor_esperado" ]
}
```

---

## 📄 Licença

Estes módulos de melhoria estão sob a mesma licença do Airgeddon original.

---

## 🤝 Contribuições

Para contribuir com melhorias:

1. Crie um branch: `git checkout -b feature/melhoria`
2. Implemente e teste: `bats tests/`
3. Envie PR com documentação

---

## 📞 Suporte

Para dúvidas ou issues:

- 📧 Email: v1s1t0r.1s.h3r3@gmail.com
- 💬 Discord: https://discord.gg/sQ9dgt9
- 🌐 GitHub: https://github.com/v1s1t0r1sh3r3/airgeddon

---

**Última atualização:** 19 de Fevereiro de 2025  
**Versão:** 1.0  
**Compatibilidade:** Bash 4.2+
