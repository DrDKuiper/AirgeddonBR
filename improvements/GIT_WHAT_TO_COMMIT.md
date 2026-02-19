# ✅ Git - O Que Incluir/Excluir

## 📋 Resumo Rápido

```
✅ INCLUIR no Git         ❌ NÃO INCLUIR no Git
─────────────────────────────────────────────────────────
*.sh (código)             .logs/ (arquivos de log)
*.bats (testes)           /tmp/ (arquivos temporários)
*.md (documentação)       /reports/ (saída de programas)
*.txt (conteúdo)          .env (configuração local)
.gitignore               .vscode/ (config pessoal)
.gitattributes           .idea/ (config pessoal)
.editorconfig            *.swp *.swo (editor backup)
SETUP.md                 __pycache__/ (cache Python)
GIT_GUIDE.md             node_modules/ (npm packages)
ALL core/                .DS_Store (macOS)
ALL tools/               *.log (logs)
ALL ui/                  Thumbs.db (Windows)
ALL tests/
```

---

## 📁 Estrutura de Diretórios

### Será Versionado ✅
```
improvements/
├── .gitignore                      ✅
├── .gitattributes                  ✅
├── .editorconfig                   ✅
├── core/                           ✅
│   └── logging.sh                 ✅
├── tools/                          ✅
│   ├── vulnerability_analyzer.sh  ✅
│   └── report_generator.sh        ✅
├── ui/                             ✅
│   ├── dashboard.sh               ✅
│   ├── ui_components.sh           ✅
│   ├── tui_manager.sh             ✅
│   └── network_viewer.sh          ✅
├── tests/                          ✅
│   ├── test_logging.bats          ✅
│   ├── test_vulnerability_analyzer.bats ✅
│   ├── test_dashboard.bats        ✅
│   └── test_dashboard_quick.sh    ✅
├── demo.sh                        ✅
├── demo_dashboard.sh              ✅
├── README.md                      ✅
├── QUICKSTART.md                  ✅
├── DASHBOARD_TECHNICAL.md         ✅
├── IMPLEMENTATION_REPORT.md       ✅
├── FILES_MANIFEST.md              ✅
├── COMPLETION_SUMMARY.txt         ✅
├── GIT_GUIDE.md                   ✅
└── SETUP.md                       ✅
```

### NÃO Será Versionado ❌
```
improvements/
├── .logs/                          ❌ Ignorado por .gitignore
│   ├── airgeddon_main.log
│   ├── airgeddon_audit.log
│   └── airgeddon_error.log
├── /tmp/                           ❌ Ignorado por .gitignore
│   └── *.tmp
├── /reports/                       ❌ Ignorado por .gitignore
│   ├── report_*.json
│   ├── report_*.html
│   └── report_*.csv
├── .vscode/                        ❌ Ignorado por .gitignore
├── .idea/                          ❌ Ignorado por .gitignore
├── .env                            ❌ Ignorado por .gitignore
├── *.log                           ❌ Ignorado por .gitignore
├── *.swp / *.swo                   ❌ Ignorado por .gitignore
├── .DS_Store                       ❌ Ignorado por .gitignore
├── Thumbs.db                       ❌ Ignorado por .gitignore
└── __pycache__/                    ❌ Ignorado por .gitignore
```

---

## 🔍 Verificar Antes de Fazer Commit

### 1. Ver Status
```bash
git status
```

**Esperado:**
```
On branch main
Your branch is up to date with 'origin/main'.

Changes to be committed:
  new file:   core/logging.sh
  new file:   ui/dashboard.sh
  (etc - apenas arquivos listados em ✅ acima)

Untracked files:
  (none)
```

**NÃO esperado:**
```
.logs/airgeddon_main.log
/tmp/test_output.txt
/reports/report_123.json
.env
```

### 2. Listar Arquivos que Serão Commitados
```bash
git ls-files
```

**Esperado:**
```
.editorconfig
.gitattributes
.gitignore
GIT_GUIDE.md
QUICKSTART.md
README.md
SETUP.md
core/logging.sh
demo.sh
demo_dashboard.sh
tests/test_dashboard.bats
tests/test_dashboard_quick.sh
tests/test_logging.bats
tests/test_vulnerability_analyzer.bats
tools/report_generator.sh
tools/vulnerability_analyzer.sh
ui/dashboard.sh
ui/network_viewer.sh
ui/tui_manager.sh
ui/ui_components.sh
```

**Total esperado:** ~20 arquivos

### 3. Verificar Arquivos Ignorados
```bash
# Ver o que será ignorado
git check-ignore -v $(find . -type f)
```

**Esperado:**
```
./.logs/airgeddon_audit.log read from .gitignore
./.logs/airgeddon_error.log read from .gitignore
./.logs/airgeddon_main.log read from .gitignore
./test_output.swp read from .gitignore
./report_2026_02_19.json read from .gitignore
```

---

## 🚀 Workflow de Commit

### Passo 1: Verificar Status
```bash
git status

# Verificar se não há arquivos que NÃO deveriam estar aí
```

### Passo 2: Adicionar Arquivos
```bash
# Adicionar tudo (seguro se .gitignore está correto)
git add .

# Ou ser seletivo
git add core/logging.sh
git add ui/dashboard.sh
# etc
```

### Passo 3: Verificar Staging Area
```bash
# Ver o que será commitado
git diff --cached --stat

# Ver diferenças detalhadas
git diff --cached
```

### Passo 4: Fazer Commit
```bash
git commit -m "Mensagem descritiva"
```

### Passo 5: Fazer Push
```bash
git push origin main
```

---

## ⚠️ Problemas Comuns

### Problema 1: Arquivo Temporário foi Commitado
```bash
# Exemplo: .logs/airgeddon_main.log foi para Git

# Solução:
git rm --cached .logs/airgeddon_main.log
git commit -m "Remove accidentally committed log file"

# Depois atualizar .gitignore se necessário
echo ".logs/" >> .gitignore
```

### Problema 2: Arquivo que Deveria Estar foi Ignorado
```bash
# Exemplo: core/new_module.sh não aparece em git status

# Solução:
git add -f core/new_module.sh  # Force add
# Ou remover a regra do .gitignore que nega o arquivo
```

### Problema 3: Os Últimos Commits Têm Arquivos Indesejados
```bash
# Solução (reescrever histórico - cuidado!)
git filter-branch --index-filter \
  'git rm --cached --ignore-unmatch .env' \
  HEAD

# Avisar à equipe se você pusha isso!
```

---

## 📊 Tamanho do Repositório

### Com .gitignore Correto
```
Arquivos versionados:     ~20 arquivos
Linhas de código:         ~3000 linhas (.sh)
Linhas de testes:         ~500 linhas (.bats)
Linhas de documentação:   ~2500 linhas
─────────────────────────────────
Tamanho estimado:         ~200KB (sem .git)
Histórico Git:            ~100KB (.git/objects)
Total:                    ~300KB
```

### Sem .gitignore (ERRADO)
```
Tamanho estimado:         ~500KB (sem .git)
Histórico Git:            ~200KB+ (.git/objects)
Total:                    ~700KB+
```

**Economia com .gitignore**: ~400KB! 📉

---

## ✅ Checklist Final

Antes de fazer `git push`:

- [ ] Ran `git status` - without unwanted files
- [ ] Ran `git ls-files` - only expected files
- [ ] Ran `.gitignore` validation - no temporary files
- [ ] No `.env` files
- [ ] No `.logs/` directory
- [ ] No `/reports/` directory
- [ ] No editor config directories
- [ ] Commit message is descriptive
- [ ] Tests are passing
- [ ] No large binary files (>1MB)

---

## 📚 Referências Rápidas

```bash
# Ver status
git status

# Ver arquivos versionados
git ls-files

# Ver arquivos ignorados
git check-ignore -v <arquivo>

# Listar tamanho de arquivos
du -sh <arquivo>

# Ver histórico de commits
git log --oneline -10

# Ver diferenças
git diff

# Desfazer último commit (local apenas)
git reset HEAD~1
```

---

## 🎯 TL;DR (Muito Longo; Não Li)

**O que committar:**
- ✅ Scripts `.sh` e `.bats`
- ✅ Documentação `.md` e `.txt`
- ✅ Arquivos de config (`.gitignore`, `.editorconfig`, etc)

**O que NÃO committar:**
- ❌ `.logs/` (arquivos de log)
- ❌ `/tmp/` (arquivos temporários)
- ❌ `/reports/` (saída de programas)
- ❌ `.env` (configuração local)
- ❌ `.vscode/`, `.idea/` (config pessoal)
- ❌ `*.log` (todos os arquivos de log)

**Antes de fazer push:**
```bash
git status      # Deve estar limpo
git ls-files    # Deve ter ~20 arquivos
```

---

✨ **Pronto para fazer commit!** 🚀

```bash
git add .
git commit -m "[FEAT] Add main features"
git push origin main
```
