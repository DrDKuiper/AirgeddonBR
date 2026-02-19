# 🔧 Setup & Development Guide - Airgeddon Improvements

## 📋 Índice
1. [Requisitos do Sistema](#requisitos-do-sistema)
2. [Setup Inicial](#setup-inicial)
3. [Documentação de Estrutura](#documentação-de-estrutura)
4. [Como Contribuir](#como-contribuir)
5. [Padrões de Código](#padrões-de-código)

---

## ✅ Requisitos do Sistema

### Obrigatório
- **Bash** 4.2+ (mínimo)
- **Git** (para versionamento)

### Verificar Versão
```bash
bash --version          # Precisa: >= 4.2
git --version           # Precisa: >= 2.0
tput colors             # Precisa: >= 8 cores
```

### Instalar (Se Necessário)

**Ubuntu/Debian**
```bash
sudo apt-get update
sudo apt-get install bash git
```

**macOS**
```bash
brew install bash git
```

**Windows (WSL2)**
```bash
wsl --install -d Ubuntu
# Depois dentro do WSL:
sudo apt-get install bash git
```

---

## 🚀 Setup Inicial

### 1. Clone ou Acesse o Repositório
```bash
# Se já tem o projeto
cd AirgeddonBR-master/improvements

# Se vai clonar (exemplo)
git clone https://github.com/seu-usuario/airgeddon-improvements.git
cd airgeddon-improvements
```

### 2. Instale Dependências de Teste (Opcional)
```bash
# Para rodar testes BATS
sudo apt-get install bats

# Ou compile do GitHub
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### 3. Verifique a Instalação
```bash
bash test_dashboard_quick.sh
# Esperado: "✓ All tests passed!"
```

### 4. Configure Git (Primeiro Commit)
```bash
git config --local user.name "Seu Nome"
git config --local user.email "seu.email@example.com"
```

---

## 📁 Documentação de Estrutura

### Diretórios Principais

```
improvements/
│
├── 📁 core/                    Sistema de logging
│   └── logging.sh             (450+ linhas, 10+ funções)
│
├── 📁 tools/                   Ferramentas de análise
│   ├── vulnerability_analyzer.sh  (600+ linhas, 8+ funções)
│   └── report_generator.sh        (550+ linhas, 6+ funções)
│
├── 📁 ui/                      Interface de usuário em TUI
│   ├── dashboard.sh            (600+ linhas, 20+ funções)
│   ├── ui_components.sh        (250+ linhas, 25+ funções)
│   ├── tui_manager.sh          (200+ linhas, 15+ funções)
│   └── network_viewer.sh       (200+ linhas, 15+ funções)
│
├── 📁 tests/                   Suite de testes automatizados
│   ├── test_logging.bats       (35 testes)
│   ├── test_vulnerability_analyzer.bats  (40+ testes)
│   └── test_dashboard.bats     (50+ testes)
│
└── 📁 docs/                    Documentação
    ├── README.md               (Guia completo)
    ├── QUICKSTART.md           (Início rápido)
    ├── DASHBOARD_TECHNICAL.md  (Especificação)
    ├── GIT_GUIDE.md            (Uso do Git)
    ├── SETUP.md                (Este arquivo)
    └── ...
```

### Arquivos Especiais

| Arquivo | Propósito | Editável? |
|---------|-----------|-----------|
| `.gitignore` | O que não versionar | ✅ Sim |
| `.gitattributes` | Configuração de line endings | ✅ Sim |
| `GIT_GUIDE.md` | Como usar Git | ✅ Sim |
| `SETUP.md` | Setup e desenvolvimento | ✅ Sim |

---

## 👨‍💻 Como Contribuir

### 1. Criar Branch para Sua Feature
```bash
# Nomenclatura: feature/nome-descritivo
git checkout -b feature/threat-intelligence

# Ou para bugfix: bugfix/descricao-do-bug
git checkout -b bugfix/dashboard-sorting
```

### 2. Fazer Alterações
```bash
# Editar arquivos
vim ui/dashboard.sh
nano core/logging.sh
# etc

# Testar alterações
bash test_dashboard_quick.sh
bats tests/test_*.bats
```

### 3. Commit com Mensagem Descritiva
```bash
git add .
git commit -m "[FEAT] Add threat intelligence module

Implements BSSID reputation checking through public threat databases.
Resolves issue #42

- Added new function analyze_threat_reputation()
- Integrated with existing risk scoring
- Added 15 new test cases"
```

### 4. Push e Pull Request
```bash
# Push da branch
git push origin feature/threat-intelligence

# No GitHub/GitLab:
# 1. Abrir Pull Request (botão automático)
# 2. Descrever mudanças
# 3. Aguardar review e merge
```

---

## 📝 Padrões de Código

### Estilo Bash

#### 1. Shebang e Cabeçalho
```bash
#!/bin/bash

################################################################################
# Nome do módulo - Descrição breve
# 
# Purpose: O que faz
# Version: X.Y
# License: GPL3
# 
# Description:
#   Descrição mais detalhada do que o módulo faz
#   pode usar múltiplas linhas
################################################################################
```

#### 2. Variáveis Globais
```bash
# Use declare -r para constantes
declare -r OPTION_DEBUG=false
declare -r LOG_DIR="./.logs"

# Use declare -g para globais mutáveis
declare -g LOG_FILE=""
declare -g LOG_LEVEL="INFO"
```

#### 3. Nomes de Funções
```bash
# snake_case para funções
initialize_tui() { ... }
add_network() { ... }
calculate_risk_score() { ... }

# Não use: InitializeTui, AddNetwork, calculateRiskScore
```

#### 4. Comentários
```bash
# Comentário simples (usar # simples)
local exit_code=$?

# Para seções maiores, usar separadores
# ============================================================================
# AUTHENTICATION
# ============================================================================

# Para documentação de função, usar comentário no topo
# Function: calculate_risk_score()
# Purpose: Calculate network risk from 0-100
# Args:    $1=bssid, $2=encryption, $3=signal
# Returns: Risk score (0-100)
calculate_risk_score() {
    ...
}
```

#### 5. Tratamento de Erros
```bash
# Verificar se arquivo existe
if [[ ! -f "$file_path" ]]; then
    echo "Error: File not found: $file_path" >&2
    return 1
fi

# Verificar resultado de comando
if ! grep -q "$pattern" "$file"; then
    log_error "Pattern not found"
    return 1
fi

# Verificar variáveis não vazias
if [[ -z "$variable" ]]; then
    log_error "Variable is empty"
    return 1
fi
```

#### 6. Quoting
```bash
# Sempre quote variáveis (exceto em casos especiais)
echo "File: $file_name"      # ✅ Correto
echo "File: $file name"      # ❌ Errado

# Use quotes duplas para expansão
echo "User home: $HOME"      # ✅ Expande variável

# Use quotes simples para literais
echo 'Use $VAR to access'    # ✅ Não expande
```

#### 7. Funções Export
```bash
# No final do arquivo, export funções públicas
export -f add_network
export -f calculate_risk_score
export -f display_network_list
```

### Documentação de Código

#### Comentário em Bloco para Funções
```bash
# Function: analyze_vulnerability
# Purpose: Analyze network for known vulnerabilities
# Args:
#   $1 - BSSID (MAC address)
#   $2 - Encryption type (WEP, WPA, WPA2, WPA3)
#   $3 - Signal strength (dBm)
# Returns:
#   0 - Success
#   1 - Error
# Output:
#   Prints risk assessment to stdout
analyze_vulnerability() {
    local bssid="$1"
    local encryption="$2"
    local signal="$3"
    
    # ... função ...
}
```

#### Inline Comments
```bash
# Explicar lógica complexa
local strength=$(( (-30 - signal) * 100 / 70 ))  # Normalize to 0-100
```

### Testes BATS

#### Estrutura de Teste
```bash
@test "description of what gets tested" {
    # Arrange: Setup
    add_network "AA:BB:CC:DD:EE:FF" "TestSSID" "WPA2" "-50dBm" "6"
    
    # Act: Execute
    local result
    result=$(get_network_data "AA:BB:CC:DD:EE:FF" "essid")
    
    # Assert: Verify
    [[ "$result" == "TestSSID" ]]
}
```

#### Nomeação de Testes
```bash
# ✅ BOM: Descreve o que testa
@test "add_network stores ESSID correctly" { ... }
@test "sort_networks by signal works descending" { ... }

# ❌ RUIM: Genérico ou incompleto
@test "test add_network" { ... }
@test "network function works" { ... }
```

---

## 🧪 Executar Testes

### Teste Rápido
```bash
bash test_dashboard_quick.sh
```

### Testes Específicos
```bash
# Logging system
bats tests/test_logging.bats

# Vulnerability analyzer
bats tests/test_vulnerability_analyzer.bats

# Dashboard
bats tests/test_dashboard.bats

# Todos os testes
bats tests/test_*.bats
```

### Com Verbose
```bash
bats tests/test_dashboard.bats -v
```

---

## 📊 Checklist de Qualidade

Antes de fazer commit/push:

### Código
- [ ] Cumpre padrões de estilo (snake_case, comentários, etc)
- [ ] Não tem variáveis não declaradas (`declare` no início)
- [ ] Funções têm comentário de propósito
- [ ] Trata erros appropriadamente
- [ ] Sem linhas muito longas (máx 100 caracteres)

### Testes
- [ ] Todos os testes passam (`bats tests/test_*.bats`)
- [ ] Adicionei testes para novas funcionalidades
- [ ] Testes cobrem casos de sucesso e erro
- [ ] Testes têm nomes descritivos

### Documentação
- [ ] Atualizei README.md se necessário
- [ ] Adicionei exemplos de uso para funções novas
- [ ] Comentei código complexo
- [ ] Sem typos na documentação

### Git
- [ ] Commit message é descritiva
- [ ] Incluído número da issue (#123) se relevante
- [ ] Usando tipo correto ([FEAT], [FIX], [TEST], etc)
- [ ] Sem arquivos desnecessários (logs, .env, etc)

---

## 🚀 Exemplo de Fluxo Completo

```bash
# 1. Criar branch
git checkout -b feature/geolocation-analysis

# 2. Fazer alterações
vim tools/geolocation.sh
echo "local latitude=\$1" >> tools/geolocation.sh

# 3. Testar
bash test_dashboard_quick.sh
bats tests/test_*.bats

# 4. Adicionar e commit
git add tools/geolocation.sh
git commit -m "[FEAT] Add geolocation analysis module

Implements RSSI triangulation for network location estimation.
Uses signal strength data from multiple access points.

- Added calculate_position() function
- Integrated with vulnerability analyzer
- Added 10 test cases"

# 5. Push
git push origin feature/geolocation-analysis

# 6. Criar Pull Request no GitHub/GitLab
# (Botão automático após push)
```

---

## 📚 Referências

### Documentação Interna
- [README.md](README.md) - Guia completo
- [GIT_GUIDE.md](GIT_GUIDE.md) - Como usar Git
- [QUICKSTART.md](QUICKSTART.md) - Início rápido
- [DASHBOARD_TECHNICAL.md](DASHBOARD_TECHNICAL.md) - Especificação

### Referências Externas
- [Bash Style Guide](https://google.github.io/styleguide/shellstyle.html)
- [BATS Documentation](https://github.com/bats-core/bats-core)
- [Git Documentation](https://git-scm.com/doc)
- [Conventional Commits](https://www.conventionalcommits.org)

---

## ✅ Você está pronto para contribuir! 🎉

Qualquer dúvida? Veja os arquivos de documentação ou abra uma issue.

**Próximos passos:**
1. Ler [QUICKSTART.md](QUICKSTART.md)
2. Executar `bash test_dashboard_quick.sh`
3. Criar sua branch: `git checkout -b feature/sua-feature`
4. Fazer alterações e testes
5. Fazer commit e push
6. Abrir Pull Request

Boa sorte! 🚀
