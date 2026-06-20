# MCP + OpenRouter + Devin + Android — Setup Automatizado

Script PowerShell 100% automatizado para configurar ambiente de desenvolvimento completo no Windows 10/11: MCP (Model Context Protocol), OpenRouter, Ollama, Android SDK, Java, Python e ferramentas auxiliares.

---

## Requisitos

- Windows 10/11 64-bit
- Conexão com internet
- ~20 GB de espaço livre em disco

---

## Instalação

### Baixar e executar

```powershell
cd $HOME\Desktop
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/canalqb/mcpopenrouter/main/setup.ps1" -OutFile "setup.ps1"
powershell -ExecutionPolicy Bypass -File setup.ps1
```

### Execução direta (sem download)

```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/canalqb/mcpopenrouter/main/setup.ps1')"
```

### Modo de teste (sem admin)

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1 -SkipAdminCheck
```

---

## Os 21 Passos do Script

### Passo 1 — Python 3.8.10
Verifica se o Python 3.8 está instalado. Se não estiver, tenta instalar via winget, chocolatey ou download direto do instalador oficial (`python-3.8.10-amd64.exe`).

### Passo 2 — setup.py
Executa o script `setup.py` do repositório (se existir) para configurações iniciais do projeto.

### Passo 3 — Node.js
Verifica/instala o Node.js via winget, chocolatey ou download manual. Necessário para executar servidores MCP via `npx`.

### Passo 4 — npx
Verifica se o npx está disponível (geralmente incluso no Node.js).

### Passo 5 — Java JDK 17
Verifica/instala o Eclipse Temurin JDK 17. Essencial para o Android SDK e ferramentas de build (aapt2, d8, apksigner).

### Passo 6 — ADB (Android Debug Bridge)
Verifica se o `adb.exe` está no PATH ou em `%LOCALAPPDATA%\Android\Sdk\platform-tools\`. Se não estiver, baixa o `platform-tools-latest-windows.zip` do Google e extrai no diretório padrão do SDK.

### Passo 7 — Android Command Line Tools
Baixa o `commandlinetools-win-11076708_latest.zip` do Google e instala em `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\`. Em seguida, usa o `sdkmanager.bat` para:
- Aceitar as licenças do Android SDK
- Instalar `platform-tools` (adb)
- Instalar `build-tools;34.0.0`
- Instalar `platforms;android-34`

Adiciona `cmdline-tools\latest\bin` e `platform-tools` ao PATH permanentemente via registro do usuário.

### Passo 8 — Notepad++
Verifica/instala o Notepad++ via winget ou chocolatey. Opcional — continua mesmo se falhar.

### Passo 9 — RustDesk
Verifica se o RustDesk (acesso remoto) está instalado. Opcional — apenas avisa e continua.

### Passo 10 — Ollama
Verifica/instala o Ollama (runtime local para LLMs) via winget, chocolatey ou download do instalador oficial (`OllamaSetup.exe`). Adiciona ao PATH da sessão atual.

### Passo 11 — Modelo Ollama
Baixa o modelo `llama3` (~4.7 GB) via `ollama pull llama3`.

### Passo 12 — Base de Conhecimento
Cria o diretório `knowledge_base\` e baixa o documento de regras do Google Docs. Gera o script `update_knowledge.ps1` para atualizações futuras.

### Passo 13 — OpenCode
Verifica/instala o OpenCode (`opencode-ai`) globalmente via npm.

### Passo 14 — Token OpenRouter
Tenta ler o token `OPENROUTER_TOKEN` do GitHub Secrets via `gh secret view`. Se não conseguir, solicita manualmente ao usuário. Salva em `.env` como `OPENAI_API_KEY`.

### Passo 15 — Dependências Python
Instala os pacotes listados em `requirements.txt` via `pip install -r requirements.txt`.

### Passo 16 — PATH do Windows
Verifica se diretórios importantes (`Python Scripts`, `Node.js`) estão no PATH do usuário. Apenas avisa se estiverem faltando — não modifica automaticamente.

### Passo 17 — Config MCP Windsurf
Cria `~\.codeium\windsurf\mcp_config.json` com servidor `filesystem` apontando para o diretório do projeto.

### Passo 18 — Config MCP Devin
Cria `%APPDATA%\Devin\mcp_config.json` com a mesma configuração do servidor filesystem.

### Passo 19 — Testar Servidor MCP
Testa o servidor MCP filesystem executando `npx -y @modelcontextprotocol/server-filesystem` em segundo plano (timeout de 30s).

### Passo 20 — Garantir python-dotenv
Instala o pacote `python-dotenv` via pip como garantia adicional.

### Passo 21 — Verificação Final
Testa cada componente instalado e exibe um resumo com o status (OK/ERRO) de cada um.

---

## Componentes Instalados

### Linguagens e Runtimes
| Componente | Versão | Instalação |
|---|---|---|
| Python | 3.8.10 | `winget`, `choco` ou download direto |
| Node.js | LTS | `winget` ou `choco` |
| Java JDK | 17 (Temurin) | `winget` ou `choco` |

### Android SDK
| Componente | Local |
|---|---|
| Command Line Tools | `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin\` |
| Platform Tools (ADB) | `%LOCALAPPDATA%\Android\Sdk\platform-tools\` |
| Build Tools 34.0.0 | `%LOCALAPPDATA%\Android\Sdk\build-tools\34.0.0\` |
| Android Platform 34 | `%LOCALAPPDATA%\Android\Sdk\platforms\android-34\` |

### IA / LLM
| Componente | Descrição |
|---|---|
| Ollama | Runtime local para LLMs |
| Modelo llama3 | Modelo padrão (~4.7 GB) |
| OpenRouter | Proxy de API para múltiplos modelos |

### MCP
| Servidor | Comando | Propósito |
|---|---|---|
| `@modelcontextprotocol/server-filesystem` | `npx -y` | Operações com arquivos (leitura, escrita, busca) |

### Ferramentas
| Ferramenta | Uso |
|---|---|
| Notepad++ | Editor de texto |
| RustDesk | Acesso remoto |
| OpenCode | CLI interativo com IA |

---

## Estrutura de Arquivos

```
%USERPROFILE%\Desktop\mcp\
├── setup.ps1                  # Script principal (21 passos)
├── setup.py                   # Configuração inicial Python
├── mcp-client.py              # Cliente MCP OpenRouter
├── requirements.txt           # Dependências Python
├── .env                       # Token OpenRouter
├── knowledge_base\
│   └── layout_rules.txt       # Regras de layout (base de conhecimento)
├── update_knowledge.ps1       # Script de atualização diária
├── README.md                  # Este arquivo
└── .opencode\
    └── AGENTS.md              # Instruções do assistente

%LOCALAPPDATA%\Android\Sdk\
├── cmdline-tools\latest\bin\  # sdkmanager.bat
├── platform-tools\            # adb.exe
├── build-tools\34.0.0\        # aapt2, d8, apksigner
└── platforms\android-34\      # android.jar

~\.codeium\windsurf\mcp_config.json     # Config MCP Windsurf
%APPDATA%\Devin\mcp_config.json         # Config MCP Devin
```

---

## Uso

### Cliente MCP Python
```powershell
python mcp-client.py
python mcp-client.py "sua pergunta aqui"
```

### OpenCode
```powershell
opencode --model ollama/antigravity-sonnet
```

### ADB
```powershell
adb devices
adb install app.apk
adb logcat
```

### Android SDK (build de APK)
```powershell
# Compilar com aapt2 + d8 + apksigner
$ANDROID_HOME\build-tools\34.0.0\aapt2.exe compile -o output *.java
```

---

## Solução de Problemas

### Script não executa como administrador
```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1 -SkipAdminCheck
```
Alguns passos (instalação de programas) podem falhar sem admin.

### Python 3.8 não é encontrado
Instale manualmente de https://www.python.org/downloads/release/python-3810/ e marque "Add Python to PATH".

### ADB não reconhece dispositivo
1. Ative o modo desenvolvedor no Android
2. Ative a depuração USB
3. Execute `adb devices`

### Ollama não encontra o modelo
```powershell
ollama pull llama3
```

### MCP não aparece na IDE
1. Verifique se `mcp_config.json` existe nos diretórios corretos
2. Reinicie a IDE
3. Verifique se o Node.js está no PATH

---

## Licença

Este projeto é fornecido como está para fins educacionais e de desenvolvimento.
