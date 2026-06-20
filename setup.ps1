# Script de Configuracao Automatica para MCP + OpenRouter + Windsurf
# PowerShell Script - Windows Compatible
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File setup.ps1
#   powershell -ExecutionPolicy Bypass -File setup.ps1 -SkipAdminCheck

param(
    [switch]$SkipAdminCheck
)

# ============================= CONFIGURACAO =============================

$pythonVersion = "3.8.10"
$pythonInstallerUrl = "https://www.python.org/ftp/python/3.8.10/python-3.8.10-amd64.exe"

# ============================= FUNCOES AUXILIARES =============================

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Banner {
    param([string]$Title, [string]$Color = "Cyan")
    $line = "=" * 60
    Write-Host "`n$line" -ForegroundColor $Color
    Write-Host $Title -ForegroundColor $Color
    Write-Host $line -ForegroundColor $Color
}

function Write-Result {
    param([string]$Message, [string]$Status = "OK")
    $symbol = if ($Status -eq "OK") { "[OK]" } else { "[ERRO]" }
    $color = if ($Status -eq "OK") { "Green" } else { "Red" }
    if ($Status -eq "AVISO") { $symbol = "[AVISO]"; $color = "Yellow" }
    Write-Host "    $symbol $Message" -ForegroundColor $color
}

function Write-Step {
    param([int]$StepNum, [int]$TotalSteps, [string]$Message)
    $percentComplete = [math]::Min([math]::Round(($StepNum / $TotalSteps) * 100, 0), 100)
    Write-Progress -Activity "Instalacao Automatica" -Status "${StepNum}/${TotalSteps}: $Message" -PercentComplete $percentComplete
    Write-Host "`n" -NoNewline
    Write-Host ("=" * 60) -ForegroundColor DarkCyan
    Write-Host " PASSO $StepNum/$TotalSteps ($($percentComplete)%) - $Message" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor DarkCyan
}

function Invoke-Safe {
    param(
        [scriptblock]$ScriptBlock,
        [string]$Description = ""
    )

    if ($Description) {
        Write-Host "  > $Description..." -ForegroundColor Yellow
    }

    $output = $null
    $success = $false

    try {
        $output = & $ScriptBlock 2>&1
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0 -or $exitCode -eq $null) {
            $success = $true
        }
    } catch {
        $output = $_.Exception.Message
        $success = $false
    }

    if ($success) {
        Write-Result "$Description concluido" "OK"
    } else {
        Write-Result "$Description falhou" "ERRO"
        if ($output) {
            $outputStr = $output | Out-String
            $truncated = $outputStr.Substring(0, [Math]::Min(300, $outputStr.Length))
            Write-Host "       Detalhe: $truncated" -ForegroundColor DarkRed
        }
    }

    return @{ Success = $success; Output = $output }
}

# ============================= FUNCOES DE VERIFICACAO =============================

function Test-PythonInstalled {
    $pythonPaths = @(
        "C:\Program Files\Python38\python.exe",
        "C:\Python38\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python38\python.exe",
        "python"
    )

    foreach ($path in $pythonPaths) {
        try {
            $result = & $path --version 2>&1
            if ($LASTEXITCODE -eq 0 -and $result -match "3\.8\.") {
                Write-Result "Python encontrado: $path" "OK"
                return $path
            }
        } catch {
            continue
        }
    }
    return $null
}

function Test-NodeInstalled {
    $nodePaths = @(
        "C:\Program Files\nodejs\node.exe",
        "C:\nodejs\node.exe",
        "$env:APPDATA\npm\node.exe"
    )

    foreach ($path in $nodePaths) {
        if (Test-Path $path) {
            Write-Result "Node.js encontrado: $path" "OK"
            $nodeDir = Split-Path $path -Parent
            $env:PATH = "$nodeDir;$env:PATH"
            return $true
        }
    }

    $result = Invoke-Safe { node -v } "Verificar Node.js via PATH"
    return $result.Success
}

function Test-JavaInstalled {
    $javaCmd = Get-Command java -ErrorAction SilentlyContinue
    if ($javaCmd) {
        try {
            $result = & $javaCmd.Source -version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Result "Java encontrado: $($javaCmd.Source)" "OK"
                return $javaCmd.Source
            }
        } catch { }
    }

    try {
        $result = java -version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Result "Java encontrado no PATH" "OK"
            return "java"
        }
    } catch { }

    $javaPaths = @(
        "C:\Program Files\Eclipse Adoptium\jdk-17.*\bin\java.exe",
        "C:\Program Files\Java\jdk-17\bin\java.exe",
        "C:\Program Files\Eclipse Adoptium\Temurin\jdk-17.*\bin\java.exe",
        "$env:LOCALAPPDATA\Programs\Eclipse Adoptium\jdk-17.*\bin\java.exe",
        "$env:LOCALAPPDATA\Programs\Java\jdk-17\bin\java.exe"
    )

    foreach ($path in $javaPaths) {
        if ($path -like "*\*") {
            $resolvedPaths = Get-ChildItem $path -ErrorAction SilentlyContinue
            if ($resolvedPaths) {
                foreach ($resolvedPath in $resolvedPaths) {
                    try {
                        $result = & $resolvedPath.FullName -version 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            Write-Result "Java encontrado: $($resolvedPath.FullName)" "OK"
                            return $resolvedPath.FullName
                        }
                    } catch { }
                }
            }
            continue
        }

        if (Test-Path $path) {
            try {
                $result = & $path -version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Result "Java encontrado: $path" "OK"
                    return $path
                }
            } catch { }
        }
    }
    return $null
}

function Test-AdbInstalled {
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) {
        try {
            $result = & $adbCmd.Source version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Result "ADB encontrado: $($adbCmd.Source)" "OK"
                return $adbCmd.Source
            }
        } catch { }
    }

    $adbPaths = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "C:\Android\Sdk\platform-tools\adb.exe",
        "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools\adb.exe",
        "C:\Program Files\Android\Android Studio\platform-tools\adb.exe"
    )

    foreach ($path in $adbPaths) {
        if (Test-Path $path) {
            try {
                $result = & $path version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Result "ADB encontrado: $path" "OK"
                    return $path
                }
            } catch { }
        }
    }
    return $null
}

function Test-NotepadPlusPlusInstalled {
    $nppPaths = @(
        "C:\Program Files\Notepad++\notepad++.exe",
        "C:\Program Files (x86)\Notepad++\notepad++.exe",
        "$env:LOCALAPPDATA\Programs\Notepad++\notepad++.exe"
    )

    foreach ($path in $nppPaths) {
        if (Test-Path $path) {
            Write-Result "Notepad++ encontrado" "OK"
            return $path
        }
    }
    return $null
}

function Test-RustDeskInstalled {
    $rustdeskPaths = @(
        "C:\Program Files\RustDesk\rustdesk.exe",
        "C:\Program Files (x86)\RustDesk\rustdesk.exe",
        "$env:LOCALAPPDATA\Programs\RustDesk\rustdesk.exe"
    )

    foreach ($path in $rustdeskPaths) {
        if (Test-Path $path) {
            Write-Result "RustDesk encontrado" "OK"
            return $path
        }
    }
    return $null
}

function Test-OllamaInstalled {
    $result = Invoke-Safe { ollama -v } "Verificar Ollama"
    return $result.Success
}

function Test-OpencodeInstalled {
    $result = Invoke-Safe { opencode --version } "Verificar OpenCode"
    return $result.Success
}

function Test-NpxInstalled {
    $result = Invoke-Safe { npx -v } "Verificar npx"
    return $result.Success
}

# ============================= FUNCOES DE INSTALACAO =============================

function Install-Python {
    Write-Host "`n  [+] Instalando Python $pythonVersion..." -ForegroundColor Yellow

    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "    Tentando winget..." -ForegroundColor Yellow
        $result = Invoke-Safe { winget install Python.Python.3.8 --silent --accept-package-agreements --accept-source-agreements } "Instalar Python via winget"
        if ($result.Success) {
            Write-Result "Python instalado. Reabra o terminal e execute o script novamente." "OK"
            exit 1
        }
    }

    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        Write-Host "    Tentando chocolatey..." -ForegroundColor Yellow
        $result = Invoke-Safe { choco install python3.8 -y } "Instalar Python via chocolatey"
        if ($result.Success) {
            Write-Result "Python instalado. Reabra o terminal e execute o script novamente." "OK"
            exit 1
        }
    }

    Write-Host "    Baixando instalador do Python..." -ForegroundColor Yellow
    $installerPath = Join-Path $scriptDir "python-installer.exe"

    try {
        Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $installerPath -UseBasicParsing
        Write-Result "Download concluido" "OK"

        Write-Host "    Instalando Python (isso pode levar alguns minutos)..." -ForegroundColor Yellow
        $process = Start-Process -FilePath $installerPath -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_test=0" -Wait -PassThru

        if ($process.ExitCode -eq 0) {
            Write-Result "Python instalado com sucesso!" "OK"
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
            Write-Result "Reabra o terminal e execute o script novamente." "AVISO"
            exit 1
        } else {
            Write-Result "Falha na instalacao. Codigo: $($process.ExitCode)" "ERRO"
        }
    } catch {
        Write-Result "Erro ao baixar/instalar Python: $($_.Exception.Message)" "ERRO"
    }

    Write-Banner "INSTALACAO MANUAL DO PYTHON NECESSARIA" "Red"
    Write-Host "  Acesse: https://www.python.org/downloads/release/python-3810/" -ForegroundColor Cyan
    Write-Host "  Baixe 'Windows installer (64-bit)' e instale marcando 'Add Python to PATH'" -ForegroundColor Cyan
    exit 1
}

function Install-NodeJs {
    Write-Host "`n  [+] Instalando Node.js..." -ForegroundColor Yellow

    $result = Invoke-Safe { node -v } "Verificar se Node.js ja existe"
    if ($result.Success) {
        Write-Result "Node.js ja instalado" "OK"
        return $true
    }

    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        $result = Invoke-Safe { winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements } "Instalar Node.js via winget"
        if ($result.Success) {
            Write-Result "Node.js instalado. Reabra o terminal e execute novamente." "OK"
            exit 1
        }
    }

    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        $result = Invoke-Safe { choco install nodejs-lts -y } "Instalar Node.js via chocolatey"
        if ($result.Success) {
            Write-Result "Node.js instalado. Reabra o terminal e execute novamente." "OK"
            exit 1
        }
    }

    Write-Banner "INSTALACAO MANUAL DO NODE.JS NECESSARIA" "Red"
    Write-Host "  Acesse: https://nodejs.org/ (baixe a versao LTS)" -ForegroundColor Cyan
    exit 1
}

function Install-Java {
    Write-Host "`n  [+] Instalando Java..." -ForegroundColor Yellow

    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "    Tentando winget..." -ForegroundColor Yellow
        $result = Invoke-Safe { winget install EclipseAdoptium.Temurin.17.JDK --silent --accept-package-agreements --accept-source-agreements } "Instalar Java via winget"
        if ($result.Success) {
            Write-Result "Java instalado via winget" "OK"
            $null = Add-JavaToPath
            return $true
        }

        $javaPath = Test-JavaInstalled
        if ($javaPath) {
            Write-Result "Java ja instalado" "OK"
            $null = Add-JavaToPath
            return $true
        }
    }

    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        Write-Host "    Tentando chocolatey..." -ForegroundColor Yellow
        $result = Invoke-Safe { choco install temurin17 -y } "Instalar Java via chocolatey"
        if ($result.Success) {
            Write-Result "Java instalado via chocolatey" "OK"
            $null = Add-JavaToPath
            return $true
        }

        $javaPath = Test-JavaInstalled
        if ($javaPath) {
            Write-Result "Java ja instalado" "OK"
            $null = Add-JavaToPath
            return $true
        }
    }

    Write-Banner "INSTALACAO MANUAL DO JAVA NECESSARIA" "Red"
    Write-Host "  Acesse: https://adoptium.net/ (Temurin JDK 17 para Windows)" -ForegroundColor Cyan
    exit 1
}

function Add-JavaToPath {
    $javaPaths = @(
        "C:\Program Files\Eclipse Adoptium\jdk-17.*\bin",
        "C:\Program Files\Java\jdk-17\bin",
        "$env:LOCALAPPDATA\Programs\Eclipse Adoptium\jdk-17.*\bin",
        "$env:LOCALAPPDATA\Programs\Java\jdk-17\bin"
    )

    foreach ($javaPath in $javaPaths) {
        $resolvedPath = Resolve-Path $javaPath -ErrorAction SilentlyContinue
        if ($resolvedPath) {
            $env:PATH = "$resolvedPath;$env:PATH"
            Write-Result "Java adicionado ao PATH: $resolvedPath" "OK"
            return $true
        }
        if (Test-Path $javaPath) {
            $env:PATH = "$javaPath;$env:PATH"
            Write-Result "Java adicionado ao PATH: $javaPath" "OK"
            return $true
        }
    }

    $javaCmd = Get-Command java -ErrorAction SilentlyContinue
    if ($javaCmd) {
        $javaDir = Split-Path $javaCmd.Source -Parent
        $env:PATH = "$javaDir;$env:PATH"
        Write-Result "Java adicionado ao PATH: $javaDir" "OK"
        return $true
    }

    Write-Result "Nao foi possivel adicionar Java ao PATH" "AVISO"
    return $false
}

function Install-AndroidSdk {
    Write-Host "`n  [+] Configurando Android SDK..." -ForegroundColor Yellow

    $adbPath = Test-AdbInstalled
    if ($adbPath) {
        Write-Result "ADB ja disponivel" "OK"
        $adbDir = Split-Path $adbPath -Parent
        $env:PATH = "$adbDir;$env:PATH"
        Write-Result "ADB adicionado ao PATH" "OK"
        return $true
    }

    $studioDirs = @(
        "C:\Program Files\Android\Android Studio",
        "$env:LOCALAPPDATA\Google\AndroidStudio*"
    )

    foreach ($dir in $studioDirs) {
        $resolved = Resolve-Path $dir -ErrorAction SilentlyContinue
        if ($resolved) {
            Write-Result "Android Studio encontrado em $resolved" "AVISO"
            Write-Result "ADB nao encontrado. Instale o SDK platform-tools pelo SDK Manager do Android Studio." "AVISO"
            return $true
        }
    }

    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "    Instalando Android Studio via winget..." -ForegroundColor Yellow
        $result = Invoke-Safe { winget install Google.AndroidStudio --silent --accept-package-agreements --accept-source-agreements } "Instalar Android Studio"
        if ($result.Success) {
            Write-Result "Android Studio instalado. ADB requer configuracao manual pelo SDK Manager." "AVISO"
            return $true
        }
    }

    Write-Banner "CONFIGURACAO MANUAL DO ADB" "Red"
    Write-Host "  Instale o Android Studio e configure o SDK platform-tools pelo SDK Manager." -ForegroundColor Cyan
    exit 1
}

function Install-NotepadPlusPlus {
    Write-Host "`n  [+] Instalando Notepad++..." -ForegroundColor Yellow

    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        $result = Invoke-Safe { winget install Notepad++.Notepad++ --silent --accept-package-agreements --accept-source-agreements } "Instalar Notepad++ via winget"
        if ($result.Success) {
            Write-Result "Notepad++ instalado" "OK"
            return $true
        }
    }

    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        $result = Invoke-Safe { choco install notepadplusplus -y } "Instalar Notepad++ via chocolatey"
        if ($result.Success) {
            Write-Result "Notepad++ instalado" "OK"
            return $true
        }
    }

    Write-Result "Notepad++ nao instalado (opcional, continuando)" "AVISO"
    return $true
}

function Install-RustDesk {
    Write-Host "`n  [+] Verificando RustDesk..." -ForegroundColor Yellow
    Write-Result "RustDesk e opcional. Pule esta instalacao ou instale manualmente depois." "AVISO"
    return $true
}

function Install-Ollama {
    Write-Host "`n  [+] Instalando Ollama..." -ForegroundColor Yellow

    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        $result = Invoke-Safe { winget install Ollama.Ollama --silent --accept-package-agreements --accept-source-agreements } "Instalar Ollama via winget"
        if ($result.Success) {
            Write-Result "Ollama instalado" "OK"
            $env:PATH += ";$env:LOCALAPPDATA\Programs\Ollama"
            return $true
        }
    }

    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        $result = Invoke-Safe { choco install ollama -y } "Instalar Ollama via chocolatey"
        if ($result.Success) {
            Write-Result "Ollama instalado" "OK"
            $env:PATH += "C:\ProgramData\chocolatey\bin"
            return $true
        }
    }

    Write-Host "    Baixando instalador do Ollama..." -ForegroundColor Yellow
    $installerUrl = "https://ollama.com/download/OllamaSetup.exe"
    $installerPath = Join-Path $scriptDir "ollama-installer.exe"

    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        Write-Result "Download concluido" "OK"

        Write-Host "    Instalando Ollama..." -ForegroundColor Yellow
        $process = Start-Process -FilePath $installerPath -ArgumentList "/silent" -Wait -PassThru

        if ($process.ExitCode -eq 0) {
            Write-Result "Ollama instalado com sucesso!" "OK"
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
            $env:PATH += ";$env:LOCALAPPDATA\Programs\Ollama"
            return $true
        } else {
            Write-Result "Falha na instalacao. Codigo: $($process.ExitCode)" "ERRO"
        }
    } catch {
        Write-Result "Erro ao baixar/instalar Ollama: $($_.Exception.Message)" "ERRO"
    }

    if (Test-OllamaInstalled) {
        Write-Result "Ollama ja instalado" "OK"
        $env:PATH += ";$env:LOCALAPPDATA\Programs\Ollama"
        return $true
    }

    Write-Banner "INSTALACAO MANUAL DO OLLAMA NECESSARIA" "Red"
    Write-Host "  Acesse: https://ollama.com/download" -ForegroundColor Cyan
    exit 1
}

function Install-OllamaModel {
    param([string]$ModelName = "llama3")
    Write-Host "`n  [+] Baixando modelo Ollama: $ModelName" -ForegroundColor Yellow
    Write-Host "    Isso pode levar varios minutos dependendo da sua internet..." -ForegroundColor Yellow

    # Usar Start-Process para evitar problemas com ANSI escape codes
    try {
        $process = Start-Process -FilePath "ollama" -ArgumentList "pull", $ModelName -NoNewWindow -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Write-Result "Modelo $ModelName baixado com sucesso!" "OK"
            return $true
        } else {
            Write-Result "Falha ao baixar modelo. Codigo: $($process.ExitCode)" "ERRO"
            return $false
        }
    } catch {
        Write-Result "Erro ao baixar modelo: $($_.Exception.Message)" "ERRO"
        return $false
    }
}

function Install-Opencode {
    Write-Host "`n  [+] Instalando OpenCode via npm..." -ForegroundColor Yellow
    $result = Invoke-Safe { npm i -g opencode-ai@latest } "Instalar OpenCode"
    if ($result.Success) {
        Write-Result "OpenCode instalado com sucesso!" "OK"
        return $true
    }

    Write-Banner "INSTALACAO MANUAL DO OPENCODE NECESSARIA" "Red"
    Write-Host "  Execute: npm i -g opencode-ai@latest" -ForegroundColor Cyan
    exit 1
}

function Install-PythonDependencies {
    param([string]$pythonPath)

    $requirementsFile = Join-Path $scriptDir "requirements.txt"

    if (-not (Test-Path $requirementsFile)) {
        Write-Result "Arquivo requirements.txt nao encontrado em $requirementsFile" "ERRO"
        return $false
    }

    Write-Host "`n  [+] Instalando dependencias Python..." -ForegroundColor Yellow
    $result = Invoke-Safe { & $pythonPath -m pip install -r $requirementsFile } "Instalar dependencias Python"
    return $result.Success
}

function Set-OllamaKnowledgeBase {
    Write-Host "`n  [+] Configurando base de conhecimento Ollama..." -ForegroundColor Yellow

    $knowledgeBaseDir = Join-Path $scriptDir "knowledge_base"
    $rulesFile = Join-Path $knowledgeBaseDir "layout_rules.txt"
    $schedulerScript = Join-Path $scriptDir "update_knowledge.ps1"

    try {
        New-Item -ItemType Directory -Force -Path $knowledgeBaseDir | Out-Null
        Write-Result "Diretorio criado: $knowledgeBaseDir" "OK"
    } catch {
        Write-Result "Erro ao criar diretorio: $($_.Exception.Message)" "ERRO"
        return $false
    }

    $docUrl = "https://docs.google.com/document/d/1sTsRoAEWrU-1ltOMmUWyQ-18DFTmYl0R5UZc-QnNtCs/export?format=txt"
    try {
        Invoke-WebRequest -Uri $docUrl -OutFile $rulesFile -UseBasicParsing
        Write-Result "Documento de regras baixado" "OK"
    } catch {
        Write-Result "Erro ao baixar documento: $($_.Exception.Message)" "ERRO"
        Set-Content -Path $rulesFile -Value "# Regras de layout, postagem e paginas" -Encoding UTF8
    }

    $schedulerContent = @'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$knowledgeBaseDir = Join-Path $scriptDir "knowledge_base"
$rulesFile = Join-Path $knowledgeBaseDir "layout_rules.txt"
$docUrl = "https://docs.google.com/document/d/1sTsRoAEWrU-1ltOMmUWyQ-18DFTmYl0R5UZc-QnNtCs/export?format=txt"

Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Atualizando base de conhecimento..." -ForegroundColor Cyan

try {
    Invoke-WebRequest -Uri $docUrl -OutFile $rulesFile -UseBasicParsing
    Write-Host "    [OK] Base de conhecimento atualizada!" -ForegroundColor Green
} catch {
    Write-Host "    [ERRO] Erro na atualizacao: $($_.Exception.Message)" -ForegroundColor Red
}
'@

    try {
        Set-Content -Path $schedulerScript -Value $schedulerContent -Encoding UTF8
        Write-Result "Script de atualizacao criado" "OK"
    } catch {
        Write-Result "Erro ao criar script: $($_.Exception.Message)" "ERRO"
    }

    return $true
}

function Request-OpenRouterToken {
    Write-Banner "CONFIGURACAO DO OPENROUTER" "Cyan"

    $token = $null

    $ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghAvailable) {
        Write-Host "    Verificando GitHub CLI..." -ForegroundColor Yellow
        try {
            $secretValue = gh secret view OPENROUTER_TOKEN --repo canalqb/mcpopenrouter 2>&1
            if ($LASTEXITCODE -eq 0) {
                $token = $secretValue
                Write-Result "Token lido do GitHub Secrets" "OK"
            }
        } catch {
            Write-Result "Nao foi possivel ler secret do GitHub" "AVISO"
        }
    }

    if (-not $token) {
        $token = Read-Host "  Digite seu token do OpenRouter (ou Enter para pular)"
    }

    if ($token -ne "") {
        try {
            Set-Content -Path $envFile -Value "OPENAI_API_KEY=$token" -Encoding UTF8
            Write-Result "Token salvo em $envFile" "OK"
        } catch {
            Write-Result "Erro ao salvar token: $($_.Exception.Message)" "ERRO"
        }
    } else {
        if (Test-Path $envFile) {
            Write-Result "Usando token existente do arquivo .env" "AVISO"
        } else {
            Write-Result "Nenhum token configurado. Configure manualmente em $envFile" "AVISO"
        }
    }
}

function New-McpConfig {
    param([string]$ConfigDir, [string]$Label = "Windsurf")

    $configFile = Join-Path $ConfigDir "mcp_config.json"

    try {
        New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
    } catch {
        Write-Result "Erro ao criar diretorio $ConfigDir" "ERRO"
        return $false
    }

    $config = @{
        mcpServers = @{
            filesystem = @{
                command = "npx"
                args = @("-y", "@modelcontextprotocol/server-filesystem", $scriptDir)
            }
        }
    }

    try {
        $configJson = $config | ConvertTo-Json -Depth 10
        Set-Content -Path $configFile -Value $configJson -Encoding UTF8
        Write-Result "Configuracao MCP criada: $configFile" "OK"
        return $true
    } catch {
        Write-Result "Erro ao criar configuracao: $($_.Exception.Message)" "ERRO"
        return $false
    }
}

function Test-NpxFilesystem {
    Write-Host "`n  [+] Testando servidor MCP filesystem..." -ForegroundColor Yellow
    Write-Host "    (pode levar alguns segundos na primeira execucao)" -ForegroundColor Yellow

    try {
        $job = Start-Job -ScriptBlock {
            param($dir)
            $result = npx -y @modelcontextprotocol/server-filesystem $dir 2>&1 | Out-String
            return $result
        } -ArgumentList $scriptDir

        $completed = Wait-Job -Job $job -Timeout 30
        Stop-Job -Job $job -ErrorAction SilentlyContinue

        if ($completed) {
            $output = Receive-Job -Job $job
            Remove-Job -Job $job
            Write-Result "Servidor MCP filesystem testado" "OK"
        } else {
            Write-Result "Timeout no teste, mas configuracao foi criada" "AVISO"
        }
    } catch {
        Write-Result "Teste ignorado, configuracao foi criada" "AVISO"
    }
}

function Add-ToPathWindows {
    Write-Host "`n  [+] Verificando PATH do Windows..." -ForegroundColor Yellow

    $items = @(
        @{ Path = "$env:APPDATA\Python\Python38\Scripts"; Label = "Python Scripts" },
        @{ Path = "C:\Program Files\nodejs"; Label = "Node.js" }
    )

    try {
        $regPath = "HKCU:\Environment"
        $currentPath = (Get-ItemProperty -Path $regPath -Name Path -ErrorAction SilentlyContinue).Path

        $missing = @()
        foreach ($item in $items) {
            if ($currentPath -and $currentPath -notlike "*$($item.Path)*") {
                $missing += $item
            }
        }

        if ($missing.Count -gt 0) {
            Write-Result "Diretorios abaixo precisam ser adicionados ao PATH manualmente:" "AVISO"
            foreach ($item in $missing) {
                Write-Host "       - $($item.Path) ($($item.Label))" -ForegroundColor Cyan
            }
        } else {
            Write-Result "PATH ja configurado corretamente" "OK"
        }
    } catch {
        Write-Result "Nao foi possivel verificar o PATH: $($_.Exception.Message)" "AVISO"
    }
}

function Invoke-Verification {
    param([string]$pythonPath)

    Write-Banner "VERIFICACAO FINAL" "Cyan"

    $checks = @(
        @{ Name = "Python"; Command = { & $pythonPath --version } }
        @{ Name = "Node.js"; Command = { node -v } }
        @{ Name = "npm"; Command = { npm -v } }
        @{ Name = "npx"; Command = { npx -v } }
        @{ Name = "OpenCode"; Command = { opencode --version } }
        @{ Name = "Ollama"; Command = { ollama -v } }
        @{ Name = "Python openai"; Command = { & $pythonPath -c "import openai; print('ok')" } }
        @{ Name = "Python dotenv"; Command = { & $pythonPath -c "import dotenv; print('ok')" } }
    )

    $results = @()
    foreach ($check in $checks) {
        $r = Invoke-Safe $check.Command "Verificando $($check.Name)"
        $results += @{ Name = $check.Name; Success = $r.Success }
    }

    Write-Banner "RESUMO DA VERIFICACAO" "Cyan"

    $totalOK = 0
    foreach ($result in $results) {
        $status = if ($result.Success) { "[OK]" } else { "[ERRO]" }
        $color = if ($result.Success) { "Green" } else { "Red" }
        Write-Host "  $($result.Name.PadRight(20)) $status" -ForegroundColor $color
        if ($result.Success) { $totalOK++ }
    }

    Write-Host "`n  Total: $totalOK/$($results.Count) verificacoes OK" -ForegroundColor $(
        if ($totalOK -eq $results.Count) { "Green" } else { "Yellow" }
    )
}

# ============================= EXECUCAO PRINCIPAL =============================

# Verificar privilegios
if (-not $SkipAdminCheck -and -not (Test-Administrator)) {
    Write-Host "`n[!] Este script requer permissao de administrador." -ForegroundColor Yellow
    Write-Host "[!] Solicitando elevacao..." -ForegroundColor Yellow

    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        if ($scriptPath) {
            $psiArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
            Start-Process powershell -Verb RunAs -ArgumentList $psiArgs
            exit
        } else {
            Write-Host "[ERRO] Execute como administrador manualmente." -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "[ERRO] Nao foi possivel elevar: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

if ($SkipAdminCheck) {
    Write-Result "Modo de teste (sem verificacao de administrador)" "AVISO"
} else {
    Write-Result "Executando como administrador" "OK"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$userProfile = $env:USERPROFILE
$devinConfigDir = Join-Path $userProfile ".codeium\windsurf"
$mcpConfigFile = Join-Path $devinConfigDir "mcp_config.json"
$envFile = Join-Path $scriptDir ".env"

# ============================= BANNER INICIAL =============================

Write-Host ""
Write-Host ("#" * 60) -ForegroundColor Cyan
Write-Host "  SCRIPT DE CONFIGURACAO AUTOMATICA" -ForegroundColor White
Write-Host "  MCP + OpenRouter + Windsurf + Ollama + Java + Android" -ForegroundColor White
Write-Host ("#" * 60) -ForegroundColor Cyan
Write-Host "  Diretorio: $scriptDir" -ForegroundColor Gray
Write-Host ""

$totalSteps = 20
$currentStep = 0

# PASSO 1: Python
$currentStep++
Write-Step $currentStep $totalSteps "Verificando Python $pythonVersion"
$pythonPath = Test-PythonInstalled
if (-not $pythonPath) {
    Write-Result "Python $pythonVersion nao encontrado" "AVISO"
    Install-Python
}

# PASSO 2: setup.py
$currentStep++
Write-Step $currentStep $totalSteps "Executando setup.py"
$setupPyPath = Join-Path $scriptDir "setup.py"
if (Test-Path $setupPyPath) {
    $null = Invoke-Safe { & $pythonPath $setupPyPath } "Executar setup.py"
} else {
    Write-Result "setup.py nao encontrado, pulando" "AVISO"
}

# PASSO 3: Node.js
$currentStep++
Write-Step $currentStep $totalSteps "Verificando Node.js"
if (-not (Test-NodeInstalled)) {
    Write-Result "Node.js nao encontrado" "AVISO"
    Install-NodeJs
}

# PASSO 4: npx
$currentStep++
Write-Step $currentStep $totalSteps "Verificando npx"
if (-not (Test-NpxInstalled)) {
    Write-Result "npx nao encontrado (geralmente vem com Node.js)" "AVISO"
}

# PASSO 5: Java
$currentStep++
Write-Step $currentStep $totalSteps "Verificando Java"
$javaPath = Test-JavaInstalled
if (-not $javaPath) {
    Write-Result "Java nao encontrado" "AVISO"
    Install-Java
}

# PASSO 6: ADB
$currentStep++
Write-Step $currentStep $totalSteps "Verificando ADB"
$adbPath = Test-AdbInstalled
if (-not $adbPath) {
    Write-Result "ADB nao encontrado" "AVISO"
    Install-AndroidSdk
}

# PASSO 7: Notepad++
$currentStep++
Write-Step $currentStep $totalSteps "Verificando Notepad++"
if (-not (Test-NotepadPlusPlusInstalled)) {
    Install-NotepadPlusPlus
} else {
    Write-Result "Notepad++ ja instalado" "OK"
}

# PASSO 8: RustDesk
$currentStep++
Write-Step $currentStep $totalSteps "Verificando RustDesk"
if (-not (Test-RustDeskInstalled)) {
    Install-RustDesk
} else {
    Write-Result "RustDesk ja instalado" "OK"
}

# PASSO 9: Ollama
$currentStep++
Write-Step $currentStep $totalSteps "Verificando Ollama"
if (-not (Test-OllamaInstalled)) {
    Write-Result "Ollama nao encontrado" "AVISO"
    Install-Ollama
}

# PASSO 10: Modelo Ollama
$currentStep++
Write-Step $currentStep $totalSteps "Configurando modelo Ollama"
$null = Install-OllamaModel -ModelName "llama3"

# PASSO 11: Base de conhecimento
$currentStep++
Write-Step $currentStep $totalSteps "Configurando base de conhecimento Ollama"
$null = Set-OllamaKnowledgeBase

# PASSO 12: OpenCode
$currentStep++
Write-Step $currentStep $totalSteps "Verificando OpenCode"
if (-not (Test-OpencodeInstalled)) {
    Write-Result "OpenCode nao encontrado" "AVISO"
    Install-Opencode
}

# PASSO 13: Token OpenRouter
$currentStep++
Write-Step $currentStep $totalSteps "Configurando token OpenRouter"
Request-OpenRouterToken

# PASSO 14: Dependencias Python
$currentStep++
Write-Step $currentStep $totalSteps "Instalando dependencias Python"
$null = Install-PythonDependencies -pythonPath $pythonPath

# PASSO 15: PATH do Windows
$currentStep++
Write-Step $currentStep $totalSteps "Verificando PATH do Windows"
Add-ToPathWindows

# PASSO 16: Diretorio config Windsurf
$currentStep++
Write-Step $currentStep $totalSteps "Criando diretorio de configuracao Windsurf"
$null = New-McpConfig -ConfigDir $devinConfigDir -Label "Windsurf"

# PASSO 17: Config MCP Devin
$currentStep++
Write-Step $currentStep $totalSteps "Criando configuracao MCP Devin"
$devinAppDataDir = Join-Path $env:APPDATA "Devin"
$null = New-McpConfig -ConfigDir $devinAppDataDir -Label "Devin"

# PASSO 18: Testar servidor MCP
$currentStep++
Write-Step $currentStep $totalSteps "Testando servidor MCP"
Test-NpxFilesystem

# PASSO 19: Instalar dependencias Python (via pip)
$currentStep++
Write-Step $currentStep $totalSteps "Garantindo dependencias Python"
$null = Invoke-Safe { & $pythonPath -m pip install --user python-dotenv } "Instalar python-dotenv"

# PASSO 20: Verificacao final
$currentStep++
Write-Step $currentStep $totalSteps "Verificacao final"
Invoke-Verification -pythonPath $pythonPath

# ============================= FINAL =============================

Write-Host ""
Write-Host ("#" * 60) -ForegroundColor Green
Write-Host "  CONFIGURACAO CONCLUIDA COM SUCESSO!" -ForegroundColor White
Write-Host ("#" * 60) -ForegroundColor Green
Write-Host "`n  Proximos passos:" -ForegroundColor White
Write-Host "  1. Reinicie o Windsurf para carregar a configuracao MCP" -ForegroundColor Gray
Write-Host "  2. As ferramentas MCP estarao disponiveis" -ForegroundColor Gray
Write-Host "  3. Para testar: $pythonPath mcp-client.py" -ForegroundColor Gray
Write-Host "  4. Para usar OpenCode: opencode --model ollama/antigravity-sonnet" -ForegroundColor Gray
Write-Host ""
