# ============================================================================
# Git Configuration Guide - Airgeddon Improvements
# ============================================================================

## 📋 Resumo

Este documento explica como configurar e usar Git com o projeto Airgeddon Improvements.

## 🗂️ Arquivos de Configuração Git

### `.gitignore`
Define quais arquivos e pastas **NÃO** devem ser versionados:
- ✗ `.logs/` - Arquivos de log gerados em tempo de execução
- ✗ `/tmp/` - Arquivos temporários
- ✗ `/reports/` - Relatórios gerados dinamicamente
- ✗ `.env` - Configurações locais (senhas, tokens, etc)
- ✗ `.vscode/`, `.idea/` - Configurações de editor pessoais

### `.gitattributes`
Define como Git trata diferentes tipos de arquivo:
- **Line endings**: Garante LF (Unix) em arquivos `.sh`, `.bats`, `.md`
- **Diff colors**: Ativa coloração especial para scripts Bash
- **Encoding**: Define UTF-8 como padrão

---

## 🚀 Como Usar com Git

### 1. Inicializar Repositório
```bash
cd improvements
git init
git add .
git commit -m "Initial commit: Airgeddon Improvements v1.0"
```

### 2. Verificar Arquivos que Serão Versionados
```bash
git status
git ls-files
```

**Esperado ser incluído:**
```
core/logging.sh
tools/vulnerability_analyzer.sh
tools/report_generator.sh
ui/dashboard.sh
ui/ui_components.sh
ui/tui_manager.sh
ui/network_viewer.sh
tests/test_*.bats
tests/test_dashboard_quick.sh
demo.sh
demo_dashboard.sh
*.md (documentação)
*.txt (COMPLETION_SUMMARY, FILES_MANIFEST)
.gitignore
.gitattributes
```

### 3. Verificar Arquivos Ignorados
```bash
git check-ignore -v */* .*
```

**Esperado ser ignorado:**
```
.logs/
/tmp/
/reports/
*.log
.env
.vscode/
```

### 4. Adicionar Arquivo ao Repositório Remoto
```bash
# Adicionar remote (exemplo com GitHub)
git remote add origin https://github.com/seu-usuario/airgeddon-improvements.git

# Push da branch main
git branch -M main
git push -u origin main
```

---

## 📊 Estrutura Versionada

```
improvements/ (versionado no Git)
├── .gitignore                      ✅ Versionado
├── .gitattributes                  ✅ Versionado
├── core/
│   └── logging.sh                 ✅ Versionado
├── tools/
│   ├── vulnerability_analyzer.sh  ✅ Versionado
│   └── report_generator.sh        ✅ Versionado
├── ui/
│   ├── dashboard.sh               ✅ Versionado
│   ├── ui_components.sh           ✅ Versionado
│   ├── tui_manager.sh             ✅ Versionado
│   └── network_viewer.sh          ✅ Versionado
├── tests/
│   ├── test_logging.bats          ✅ Versionado
│   ├── test_vulnerability_analyzer.bats ✅ Versionado
│   ├── test_dashboard.bats        ✅ Versionado
│   └── test_dashboard_quick.sh    ✅ Versionado
├── demo.sh                        ✅ Versionado
├── demo_dashboard.sh              ✅ Versionado
├── README.md                      ✅ Versionado
├── QUICKSTART.md                  ✅ Versionado
├── DASHBOARD_TECHNICAL.md         ✅ Versionado
├── IMPLEMENTATION_REPORT.md       ✅ Versionado
├── FILES_MANIFEST.md              ✅ Versionado
├── COMPLETION_SUMMARY.txt         ✅ Versionado
└── ANALISE_PROJETO.md             ✅ Versionado

improvements/ (NÃO versionado)
├── .logs/                         ❌ Ignorado
├── .vscode/                       ❌ Ignorado
├── .idea/                         ❌ Ignorado
├── /tmp/                          ❌ Ignorado
├── /reports/                      ❌ Ignorado
├── .env                           ❌ Ignorado
└── *.log                          ❌ Ignorado
```

---

## 🔧 Comandos Úteis

### Verificar Status
```bash
# Ver files que serão commitados
git status

# Ver arquivos rastreados
git ls-files

# Ver arquivos ignorados
git check-ignore -v $(find . -type f)
```

### Trabalhar com Branches
```bash
# Criar branch para nova feature
git checkout -b feature/threat-intelligence

# Fazer commit
git commit -m "Add threat intelligence module"

# Fazer push
git push origin feature/threat-intelligence

# Criar pull request (no GitHub, GitLab, etc)
```

### Sincronizar com Upstream
```bash
# Se for fork do Airgeddon original
git remote add upstream https://github.com/v1s1t0r1791/airgeddon.git
git fetch upstream
git merge upstream/master
```

---

## 💾 Estratégia de Commits

### Estrutura de Mensagem
```
[TIPO] Descrição breve (máx 50 chars)

Descrição mais detalhada se necessário
(máx 72 chars por linha)

Fixes #123
```

### Tipos de Commit
```
[FEAT]   - Nova funcionalidade
[FIX]    - Correção de bug
[DOCS]   - Atualização de documentação
[TEST]   - Adição/atualização de testes
[PERF]   - Melhorias de performance
[REFACTOR] - Refatoração de código
[STYLE]  - Formatação, sem mudança de lógica
[CI]     - Mudanças em CI/CD
```

### Exemplos
```bash
git commit -m "[FEAT] Add threat intelligence module

Implements BSSID reputation checking and botnet detection
through public threat databases.

Fixes #42"

git commit -m "[TEST] Add 20 new test cases for dashboard

Covers edge cases in network filtering and sorting"

git commit -m "[DOCS] Update integration guide with real examples"
```

---

## 🔐 Segurança

### O que NUNCA committar
- ✗ Senhas ou tokens (use `.env`)
- ✗ Chaves de API (use `.env`)
- ✗ Dados pessoais
- ✗ Arquivos binários grandes
- ✗ Dependências (npm, pip, etc) - use `package.json`, `requirements.txt`

### Se commitar por acidente
```bash
# Remover arquivo mas mantê-lo localmente
git rm --cached arquivo.txt
git commit -m "Remove arquivo sensível"

# Ou reescrever histórico (cuidado!)
git filter-branch --index-filter 'git rm --cached --ignore-unmatch arquivo.txt'
```

---

## 📈 Tamanho do Repositório

### Esperado
```
Total de código:     ~3000 linhas (.sh)
Total de testes:     ~500 linhas (.bats)
Total de docs:       ~2500 linhas (.md, .txt)
────────────────────────────────
Total no Git:        ~6000 linhas
Tamanho estimado:    ~180KB (sem .git)
```

### Otimizações Aplicadas via .gitignore
- ❌ Sem `.logs/` = -100KB
- ❌ Sem `/tmp/` = -50KB
- ❌ Sem `/reports/` = -50KB
- ❌ Sem `.vscode/` = -20KB

**Economia**: ~220KB por manter apenas essencial!

---

## 🚨 Troubleshooting

### Problema: Arquivo deveria ser ignorado mas não está
```bash
# Limpar cache do Git
git rm -r --cached .
git add .
git commit -m "Refresh gitignore"
```

### Problema: Arquivo deveria ser versionado mas foi ignorado
```bash
# Forçar adicionar arquivo ignorado
git add -f arquivo.sh
```

### Problema: Line endings incorretos (CRLF vs LF)
```bash
# Converter para LF (recomendado para Bash)
dos2unix *.sh        # ou
sed -i 's/\r$//' *.sh
```

---

## 📚 Recursos Adicionais

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Help](https://docs.github.com)
- [GitLab Help](https://docs.gitlab.com)
- [Conventional Commits](https://www.conventionalcommits.org)

---

## ✅ Checklist Antes de Pushar

- [ ] Todos os testes passam: `bats tests/test_*.bats`
- [ ] Documentação atualizada
- [ ] Sem arquivos `.log` ou temporários
- [ ] Sem credenciais expostas
- [ ] Commits com mensagens descritivas
- [ ] Código passa em ShellCheck: `shellcheck *.sh`

---

**Pronto para fazer push?** 🚀
```bash
git push origin main
```
