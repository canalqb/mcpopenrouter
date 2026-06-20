# MCP + OpenRouter + Devin - Setup Automatizado

Script de configuração 100% automático para MCP com OpenRouter e Devin, compatível com Windows 10/11.

## 📋 Visão Geral

Este script instala e configura automaticamente todas as ferramentas necessárias para desenvolvimento com MCP (Model Context Protocol), OpenRouter, Devin IDE, e ferramentas complementares para desenvolvimento Android e acesso remoto.

## 🚀 Instalação Automática (Recomendado)

Execute o script de instalação via PowerShell:

```powershell
# Opção 1: Baixar e executar
cd $HOME\Desktop
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/canalqb/mcpopenrouter/main/setup.ps1" -OutFile "setup.ps1"
powershell -ExecutionPolicy Bypass -File setup.ps1

# Opção 2: Execução direta
cd $HOME/Desktop
Invoke-Expression (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/canalqb/mcpopenrouter/main/setup.ps1")
```

## 📦 Componentes Instalados

### Linguagens e Runtimes
- **Python 3.8.10**: Ambiente Python para execução de scripts MCP
- **Node.js e npx**: Runtime JavaScript para execução de servidores MCP via npx
- **Java JDK 17**: Ambiente Java para desenvolvimento Android

### Ferramentas de Desenvolvimento Android
- **Android SDK (via Android Studio)**: SDK completo para desenvolvimento Android
- **ADB (Android Debug Bridge)**: Ferramenta de depuração e comunicação com dispositivos Android

### Editores e Ferramentas de Acesso
- **Notepad++**: Editor de texto avançado para Windows
- **RustDesk**: Ferramenta de acesso remoto (senha padrão: 2772)

### Inteligência Artificial e MCP
- **Ollama**: Runtime para execução de modelos LLM localmente
  - Modelo: antigravity-sonnet
  - PATH configurado automaticamente
  - Base de conhecimento com atualização diária
- **OpenRouter**: Integração com modelos via API
  - Configuração MCP para Devin/Cascade
  - Modelo: ollama/antigravity-sonnet

### Configurações MCP
- **Configuração MCP para Devin**: Arquivo `~/.codeium/windsurf/mcp_config.json`
- **Configuração MCP para Devin/Cascade**: Arquivo `%APPDATA%\Devin\mcp_config.json`
  - Servidor OpenRouter configurado
  - Modelo ollama/antigravity-sonnet

### Base de Conhecimento Ollama
- **Diretório**: `knowledge_base/layout_rules.txt`
- **Fonte**: Documento Google Docs com regras de layout, postagem e páginas
- **Atualização**: Script `update_knowledge.ps1` executado diariamente às 9:00 AM
- **URL**: https://docs.google.com/document/d/1sTsRoAEWrU-1ltOMmUWyQ-18DFTmYl0R5UZc-QnNtCs

### Dependências Python
- Pacotes necessários para funcionamento do cliente MCP
- Instalados via `requirements.txt`

## 🔐 Configuração do Secret

O script lê o token do OpenRouter do secret `OPENROUTER_TOKEN` do GitHub. Configure em:
https://github.com/canalqb/mcpopenrouter/settings/secrets/actions

Alternativamente, o script solicitará o token manualmente durante a execução se não encontrar o secret.

## 📝 Uso

### Cliente MCP Python
Após a instalação, execute o cliente:
```bash
python mcp-client.py
```

Ou modo automatizado:
```bash
python mcp-client.py "sua pergunta"
```

### Configuração Devin IDE
1. Reinicie o Devin IDE para carregar a configuração MCP
2. As ferramentas MCP estarão disponíveis no Cascade
3. Configure o modelo desejado nas configurações do Cascade

### Acesso Remoto (RustDesk)
- Senha padrão: 2772
- Configure dispositivos nas configurações do RustDesk
- Acesso disponível após instalação

## 🔧 Ferramentas MCP Disponíveis

- **read_file**: Ler conteúdo de arquivos
- **write_file**: Escrever conteúdo em arquivos  
- **list_directory**: Listar arquivos e diretórios
- **search_files**: Buscar arquivos por padrão
- **filesystem**: Operações seguras com sistema de arquivos

## 💻 Compatibilidade

- **Sistema**: Windows 10/11
- **Python**: 3.8.10+
- **IDE**: Devin (antigo Windsurf)
- **Arquitetura**: x64

## 📁 Estrutura de Arquivos

Após a instalação, os seguintes arquivos serão criados:
```
~/.codeium/windsurf/mcp_config.json          # Configuração MCP Devin
%APPDATA%\Devin\mcp_config.json              # Configuração MCP Cascade
knowledge_base/layout_rules.txt             # Base de conhecimento Ollama
update_knowledge.ps1                        # Script de atualização diária
.env                                         # Variáveis de ambiente
requirements.txt                             # Dependências Python
```

## 🔄 Atualização Diária da Base de Conhecimento

O script cria uma tarefa agendada do Windows que:
- Executa diariamente às 9:00 AM
- Baixa a versão mais recente do documento de regras
- Atualiza o arquivo `knowledge_base/layout_rules.txt`
- Nome da tarefa: `OllamaKnowledgeUpdate`

## 🐛 Solução de Problemas

### Ollama não funciona após instalação
- Feche e reabra o terminal para atualizar o PATH
- Execute `ollama -v` para verificar a instalação

### ADB não reconhece dispositivos
- Verifique se o modo de desenvolvedor está ativado no dispositivo
- Execute `adb devices` para listar dispositivos conectados

### RustDesk não conecta
- Verifique se a senha 2772 foi configurada corretamente
- Configure as regras de firewall se necessário

### MCP não aparece no Devin
- Reinicie o Devin IDE
- Verifique se o arquivo `mcp_config.json` foi criado corretamente
- Consulte os logs do Devin para erros

## 📄 Licença

Este projeto é fornecido como está para fins educacionais e de desenvolvimento.
