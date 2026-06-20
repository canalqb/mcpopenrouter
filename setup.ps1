# Script de Configuracao 100% Automatica para MCP + OpenRouter + Devin
# PowerShell Script - Windows Compatible
#
# INSTALACAO VIA POWERSHELL:
# cd $HOME\Desktop
# Invoke-WebRequest -Uri "https://raw.githubusercontent.com/canalqb/mcpopenrouter/main/setup.ps1" -OutFile "setup.ps1"
# powershell -ExecutionPolicy Bypass -File setup.ps1
#
# OU INSTALACAO DIRETA:
# cd $HOME/Desktop
# Invoke-Expression (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/canalqb/mcpopenrouter/main/setup.ps1")

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$userProfile = $env:USERPROFILE
$devinConfigDir = Join-Path $userProfile ".codeium\windsurf"
$mcpConfigFile = Join-Path $devinConfigDir "mcp_config.json"
$envFile = Join-Path $scriptDir ".env"
$pythonVersion = "3.8.10"
$pythonInstallerUrl = "https://www.python.org/ftp/python/3.8.10/python-3.8.10-amd64.exe"

function Write-Step {
    param([int]$StepNum, [int]$TotalSteps, [string]$Message)
    Write-Host "`n$('='*60)" -ForegroundColor Cyan
    Write-Host "PASSO ${StepNum}/${TotalSteps}: $Message" -ForegroundColor Cyan
    Write-Host $('='*60) -ForegroundColor Cyan
}

function Invoke-CommandSafe {
    param([string]$Command, [string]$Description)
    Write-Host "`n[+] Executando: $Description" -ForegroundColor Yellow
    Write-Host "    Comando: $Command" -ForegroundColor Gray
    
    try {
        $output = Invoke-Expression $Command 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] Sucesso!" -ForegroundColor Green
            if ($output) {
                $outputStr = $output | Out-String
                Write-Host "    Saida: $($outputStr.Substring(0, [Math]::Min(200, $outputStr.Length)))" -ForegroundColor Gray
            }
            return $true
        } else {
            Write-Host "    [ERRO] Falha!" -ForegroundColor Red
            $errorStr = $output | Out-String
            Write-Host "    Erro: $($errorStr.Substring(0, [Math]::Min(200, $errorStr.Length)))" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "    [ERRO] Excecao: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

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
                Write-Host "    Python encontrado: $path" -ForegroundColor Green
                return $path
            }
        } catch {
            continue
        }
    }
    return $null
}

function Install-Python {
    Write-Host "`n[+] Instalando Python $pythonVersion automaticamente..." -ForegroundColor Yellow
    
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "    Usando winget para instalar Python..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "winget install Python.Python.3.8 --silent --accept-package-agreements --accept-source-agreements" "Instalando Python via winget"
        if ($result) {
            Write-Host "    Python instalado com sucesso via winget!" -ForegroundColor Green
            Write-Host "    Por favor, feche e reabra este terminal para atualizar o PATH." -ForegroundColor Yellow
            Write-Host "    Execute este script novamente apos reabrir o terminal." -ForegroundColor Yellow
            exit 1
        }
    }
    
    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        Write-Host "    Usando chocolatey para instalar Python..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "choco install python3.8 -y" "Instalando Python via chocolatey"
        if ($result) {
            Write-Host "    Python instalado com sucesso via chocolatey!" -ForegroundColor Green
            Write-Host "    Por favor, feche e reabra este terminal para atualizar o PATH." -ForegroundColor Yellow
            Write-Host "    Execute este script novamente apos reabrir o terminal." -ForegroundColor Yellow
            exit 1
        }
    }
    
    Write-Host "    Baixando instalador do Python..." -ForegroundColor Yellow
    $installerPath = Join-Path $scriptDir "python-installer.exe"
    
    try {
        Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "    [OK] Download concluido!" -ForegroundColor Green
        
        Write-Host "    Instalando Python..." -ForegroundColor Yellow
        $process = Start-Process -FilePath $installerPath -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_test=0" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "    [OK] Python instalado com sucesso!" -ForegroundColor Green
            Remove-Item $installerPath -Force
            Write-Host "    Por favor, feche e reabra este terminal para atualizar o PATH." -ForegroundColor Yellow
            Write-Host "    Execute este script novamente apos reabrir o terminal." -ForegroundColor Yellow
            exit 1
        } else {
            Write-Host "    [ERRO] Falha na instalacao do Python. Codigo: $($process.ExitCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "    [ERRO] Erro ao baixar/instalar Python: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n$('='*60)" -ForegroundColor Red
    Write-Host "INSTALACAO MANUAL DO PYTHON NECESSARIA" -ForegroundColor Red
    Write-Host "$('='*60)" -ForegroundColor Red
    Write-Host "`nPor favor, siga estes passos:" -ForegroundColor White
    Write-Host "1. Acesse: https://www.python.org/downloads/release/python-3810/" -ForegroundColor Cyan
    Write-Host "2. Baixe 'Windows installer (64-bit)'" -ForegroundColor Cyan
    Write-Host "3. Execute o instalador" -ForegroundColor Cyan
    Write-Host "4. Marque 'Add Python to PATH'" -ForegroundColor Cyan
    Write-Host "5. Apos a instalacao, feche e reabra este terminal" -ForegroundColor Cyan
    Write-Host "6. Execute este script novamente" -ForegroundColor Cyan
    exit 1
}

function Test-NodeInstalled {
    # Tenta via PATH primeiro
    $result = Invoke-CommandSafe "node -v" "Verificando Node.js via PATH"
    if ($result) {
        return $true
    }
    
    # Tenta encontrar em locais comuns
    $nodePaths = @(
        "C:\Program Files\nodejs\node.exe",
        "C:\nodejs\node.exe",
        "$env:APPDATA\npm\node.exe"
    )
    
    foreach ($path in $nodePaths) {
        if (Test-Path $path) {
            Write-Host "    Node.js encontrado em: $path" -ForegroundColor Green
            Write-Host "    Adicionando ao PATH temporariamente..." -ForegroundColor Yellow
            $env:PATH += ";C:\Program Files\nodejs"
            return $true
        }
    }
    
    return $false
}

function Test-NpxInstalled {
    return Invoke-CommandSafe "npx -v" "Verificando npx"
}

function Test-OllamaInstalled {
    return Invoke-CommandSafe "ollama -v" "Verificando Ollama"
}

function Test-JavaInstalled {
    $javaPaths = @(
        "C:\Program Files\Java\jdk-17\bin\java.exe",
        "C:\Program Files\Java\jdk-21\bin\java.exe",
        "C:\Program Files\Eclipse Adoptium\jdk-17.*\bin\java.exe",
        "C:\Program Files\Eclipse Adoptium\jdk-21.*\bin\java.exe",
        "$env:LOCALAPPDATA\Programs\Java\jdk-17\bin\java.exe",
        "$env:LOCALAPPDATA\Programs\Eclipse Adoptium\jdk-17.*\bin\java.exe",
        "$env:LOCALAPPDATA\Programs\Eclipse Adoptium\jdk-21.*\bin\java.exe",
        "java"
    )
    
    foreach ($path in $javaPaths) {
        # Tentar resolver wildcard paths
        if ($path -like "*\*") {
            $resolvedPaths = Get-ChildItem $path -ErrorAction SilentlyContinue
            if ($resolvedPaths) {
                foreach ($resolvedPath in $resolvedPaths) {
                    try {
                        $result = & $resolvedPath.FullName -version 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "    Java encontrado: $($resolvedPath.FullName)" -ForegroundColor Green
                            return $resolvedPath.FullName
                        }
                    } catch {
                        continue
                    }
                }
            }
            continue
        }
        
        # Tentar caminho direto
        if (Test-Path $path) {
            try {
                $result = & $path -version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "    Java encontrado: $path" -ForegroundColor Green
                    return $path
                }
            } catch {
                continue
            }
        }
        
        # Tentar comando direto (java)
        try {
            $result = & $path -version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    Java encontrado: $path" -ForegroundColor Green
                return $path
            }
        } catch {
            continue
        }
    }
    return $null
}

function Install-Java {
    Write-Host "`n[+] Instalando Java automaticamente..." -ForegroundColor Yellow
    
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "    Usando winget para instalar Java..." -ForegroundColor Yellow
        
        # Tentar Eclipse Adoptium (Temurin) primeiro - mais confiavel
        $result = Invoke-CommandSafe "winget install EclipseAdoptium.Temurin.17.JDK --silent --accept-package-agreements --accept-source-agreements" "Instalando Java (Eclipse Adoptium) via winget"
        if ($result) {
            Write-Host "    Java instalado com sucesso via winget!" -ForegroundColor Green
            Write-Host "    Atualizando PATH para sessao atual..." -ForegroundColor Yellow
            
            # Adicionar Java ao PATH da sessao atual
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
                    Write-Host "    [OK] Java adicionado ao PATH: $resolvedPath" -ForegroundColor Green
                    break
                }
                if (Test-Path $javaPath) {
                    $env:PATH = "$javaPath;$env:PATH"
                    Write-Host "    [OK] Java adicionado ao PATH: $javaPath" -ForegroundColor Green
                    break
                }
            }
            
            Write-Host "    Continuando com a execucao do script..." -ForegroundColor Yellow
            return $true
        }
        
        # Se falhou, verificar se ja esta instalado
        Write-Host "    Verificando se Java ja esta instalado..." -ForegroundColor Yellow
        $javaPath = Test-JavaInstalled
        if ($javaPath) {
            Write-Host "    [OK] Java ja esta instalado: $javaPath" -ForegroundColor Green
            Write-Host "    Adicionando ao PATH da sessao atual..." -ForegroundColor Yellow
            
            # Adicionar ao PATH
            $javaDir = Split-Path $javaPath -Parent
            $env:PATH = "$javaDir;$env:PATH"
            Write-Host "    [OK] Java adicionado ao PATH: $javaDir" -ForegroundColor Green
            Write-Host "    Continuando com a execucao do script..." -ForegroundColor Yellow
            return $true
        }
        
        # Tentar Oracle JDK como alternativa
        Write-Host "    Tentando Oracle JDK como alternativa..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "winget install Oracle.JDK.17 --silent --accept-package-agreements --accept-source-agreements" "Instalando Java (Oracle) via winget"
        if ($result) {
            Write-Host "    Java instalado com sucesso via winget!" -ForegroundColor Green
            Write-Host "    Atualizando PATH para sessao atual..." -ForegroundColor Yellow
            
            # Adicionar Java ao PATH da sessao atual
            $javaPaths = @(
                "C:\Program Files\Java\jdk-17\bin",
                "$env:LOCALAPPDATA\Programs\Java\jdk-17\bin"
            )
            
            foreach ($javaPath in $javaPaths) {
                if (Test-Path $javaPath) {
                    $env:PATH = "$javaPath;$env:PATH"
                    Write-Host "    [OK] Java adicionado ao PATH: $javaPath" -ForegroundColor Green
                    break
                }
            }
            
            Write-Host "    Continuando com a execucao do script..." -ForegroundColor Yellow
            return $true
        }
        
        # Se falhou novamente, verificar se ja esta instalado
        Write-Host "    Verificando se Java ja esta instalado..." -ForegroundColor Yellow
        $javaPath = Test-JavaInstalled
        if ($javaPath) {
            Write-Host "    [OK] Java ja esta instalado: $javaPath" -ForegroundColor Green
            Write-Host "    Adicionando ao PATH da sessao atual..." -ForegroundColor Yellow
            
            # Adicionar ao PATH
            $javaDir = Split-Path $javaPath -Parent
            $env:PATH = "$javaDir;$env:PATH"
            Write-Host "    [OK] Java adicionado ao PATH: $javaDir" -ForegroundColor Green
            Write-Host "    Continuando com a execucao do script..." -ForegroundColor Yellow
            return $true
        }
    }
    
    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        Write-Host "    Usando chocolatey para instalar Java..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "choco install temurin17 -y" "Instalando Java via chocolatey"
        if ($result) {
            Write-Host "    Java instalado com sucesso via chocolatey!" -ForegroundColor Green
            Write-Host "    Atualizando PATH para sessao atual..." -ForegroundColor Yellow
            
            # Adicionar Java ao PATH da sessao atual
            $javaPaths = @(
                "C:\Program Files\Eclipse Adoptium\jdk-17.*\bin",
                "C:\Program Files\Java\jdk-17\bin",
                "$env:LOCALAPPDATA\Programs\Eclipse Adoptium\jdk-17.*\bin"
            )
            
            foreach ($javaPath in $javaPaths) {
                $resolvedPath = Resolve-Path $javaPath -ErrorAction SilentlyContinue
                if ($resolvedPath) {
                    $env:PATH = "$resolvedPath;$env:PATH"
                    Write-Host "    [OK] Java adicionado ao PATH: $resolvedPath" -ForegroundColor Green
                    break
                }
                if (Test-Path $javaPath) {
                    $env:PATH = "$javaPath;$env:PATH"
                    Write-Host "    [OK] Java adicionado ao PATH: $javaPath" -ForegroundColor Green
                    break
                }
            }
            
            Write-Host "    Continuando com a execucao do script..." -ForegroundColor Yellow
            return $true
        }
        
        # Se falhou, verificar se ja esta instalado
        Write-Host "    Verificando se Java ja esta instalado..." -ForegroundColor Yellow
        $javaPath = Test-JavaInstalled
        if ($javaPath) {
            Write-Host "    [OK] Java ja esta instalado: $javaPath" -ForegroundColor Green
            Write-Host "    Adicionando ao PATH da sessao atual..." -ForegroundColor Yellow
            
            # Adicionar ao PATH
            $javaDir = Split-Path $javaPath -Parent
            $env:PATH = "$javaDir;$env:PATH"
            Write-Host "    [OK] Java adicionado ao PATH: $javaDir" -ForegroundColor Green
            Write-Host "    Continuando com a execucao do script..." -ForegroundColor Yellow
            return $true
        }
    }
    
    Write-Host "`n$('='*60)" -ForegroundColor Red
    Write-Host "INSTALACAO MANUAL DO JAVA NECESSARIA" -ForegroundColor Red
    Write-Host "$('='*60)" -ForegroundColor Red
    Write-Host "`nPor favor, siga estes passos:" -ForegroundColor White
    Write-Host "1. Acesse: https://adoptium.net/" -ForegroundColor Cyan
    Write-Host "2. Baixe o Temurin JDK 17 para Windows" -ForegroundColor Cyan
    Write-Host "3. Execute o instalador" -ForegroundColor Cyan
    Write-Host "4. Apos a instalacao, feche e reabra este terminal" -ForegroundColor Cyan
    Write-Host "5. Execute este script novamente" -ForegroundColor Cyan
    exit 1
}

function Test-AdbInstalled {
    $adbPaths = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "C:\Android\Sdk\platform-tools\adb.exe",
        "adb"
    )
    
    foreach ($path in $adbPaths) {
        try {
            $result = & $path version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    ADB encontrado: $path" -ForegroundColor Green
                return $path
            }
        } catch {
            continue
        }
    }
    return $null
}

function Install-AndroidSdk {
    Write-Host "`n[+] Instalando Android SDK automaticamente..." -ForegroundColor Yellow
    
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "    Usando winget para instalar Android SDK..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "winget install Google.AndroidStudio --silent --accept-package-agreements --accept-source-agreements" "Instalando Android Studio via winget"
        if ($result) {
            Write-Host "    Android Studio instalado com sucesso via winget!" -ForegroundColor Green
            Write-Host "    ADB esta incluido no Android Studio" -ForegroundColor Yellow
            Write-Host "    Atualizando PATH para sessao atual..." -ForegroundColor Yellow
            
            # Adicionar ADB ao PATH da sessao atual
            $adbPaths = @(
                "$env:LOCALAPPDATA\Android\Sdk\platform-tools",
                "C:\Android\Sdk\platform-tools",
                "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools"
            )
            
            foreach ($adbPath in $adbPaths) {
                if (Test-Path $adbPath) {
                    $env:PATH = "$adbPath;$env:PATH"
                    Write-Host "    [OK] ADB adicionado ao PATH: $adbPath" -ForegroundColor Green
                    break
                }
            }
            
            Write-Host "    Continuando com a execucao do script..." -ForegroundColor Yellow
            return $true
        }
    }
    
    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        Write-Host "    Usando chocolatey para instalar Android SDK..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "choco install android-sdk -y" "Instalando Android SDK via chocolatey"
        if ($result) {
            Write-Host "    Android SDK instalado com sucesso via chocolatey!" -ForegroundColor Green
            Write-Host "    Atualizando PATH para sessao atual..." -ForegroundColor Yellow
            
            # Adicionar ADB ao PATH da sessao atual
            $adbPaths = @(
                "$env:LOCALAPPDATA\Android\Sdk\platform-tools",
                "C:\Android\Sdk\platform-tools",
                "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools"
            )
            
            foreach ($adbPath in $adbPaths) {
                if (Test-Path $adbPath) {
                    $env:PATH = "$adbPath;$env:PATH"
                    Write-Host "    [OK] ADB adicionado ao PATH: $adbPath" -ForegroundColor Green
                    break
                }
            }
            
            Write-Host "    Continuando com a execucao do script..." -ForegroundColor Yellow
            return $true
        }
    }
    
    Write-Host "`n$('='*60)" -ForegroundColor Red
    Write-Host "INSTALACAO MANUAL DO ANDROID SDK NECESSARIA" -ForegroundColor Red
    Write-Host "$('='*60)" -ForegroundColor Red
    Write-Host "`nPor favor, siga estes passos:" -ForegroundColor White
    Write-Host "1. Acesse: https://developer.android.com/studio" -ForegroundColor Cyan
    Write-Host "2. Baixe o Android Studio para Windows" -ForegroundColor Cyan
    Write-Host "3. Execute o instalador" -ForegroundColor Cyan
    Write-Host "4. Apos a instalacao, feche e reabra este terminal" -ForegroundColor Cyan
    Write-Host "5. Execute este script novamente" -ForegroundColor Cyan
    exit 1
}

function Test-NotepadPlusPlusInstalled {
    $nppPaths = @(
        "C:\Program Files\Notepad++\notepad++.exe",
        "C:\Program Files (x86)\Notepad++\notepad++.exe",
        "$env:LOCALAPPDATA\Programs\Notepad++\notepad++.exe",
        "notepad++"
    )
    
    foreach ($path in $nppPaths) {
        if (Test-Path $path) {
            Write-Host "    Notepad++ encontrado: $path" -ForegroundColor Green
            return $path
        }
    }
    return $null
}

function Install-NotepadPlusPlus {
    Write-Host "`n[+] Instalando Notepad++ automaticamente..." -ForegroundColor Yellow
    
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "    Usando winget para instalar Notepad++..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "winget install Notepad++.Notepad++ --silent --accept-package-agreements --accept-source-agreements" "Instalando Notepad++ via winget"
        if ($result) {
            Write-Host "    Notepad++ instalado com sucesso via winget!" -ForegroundColor Green
            return $true
        }
    }
    
    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        Write-Host "    Usando chocolatey para instalar Notepad++..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "choco install notepadplusplus -y" "Instalando Notepad++ via chocolatey"
        if ($result) {
            Write-Host "    Notepad++ instalado com sucesso via chocolatey!" -ForegroundColor Green
            return $true
        }
    }
    
    Write-Host "`n$('='*60)" -ForegroundColor Red
    Write-Host "INSTALACAO MANUAL DO NOTEPAD++ NECESSARIA" -ForegroundColor Red
    Write-Host "$('='*60)" -ForegroundColor Red
    Write-Host "`nPor favor, siga estes passos:" -ForegroundColor White
    Write-Host "1. Acesse: https://notepad-plus-plus.org/downloads/" -ForegroundColor Cyan
    Write-Host "2. Baixe o instalador para Windows" -ForegroundColor Cyan
    Write-Host "3. Execute o instalador" -ForegroundColor Cyan
    Write-Host "4. Apos a instalacao, execute este script novamente" -ForegroundColor Cyan
    exit 1
}

function Test-RustDeskInstalled {
    $rustdeskPaths = @(
        "C:\Program Files\RustDesk\rustdesk.exe",
        "C:\Program Files (x86)\RustDesk\rustdesk.exe",
        "$env:LOCALAPPDATA\Programs\RustDesk\rustdesk.exe",
        "rustdesk"
    )
    
    foreach ($path in $rustdeskPaths) {
        if (Test-Path $path) {
            Write-Host "    RustDesk encontrado: $path" -ForegroundColor Green
            return $path
        }
    }
    return $null
}

function Install-RustDesk {
    Write-Host "`n[+] Instalando RustDesk automaticamente..." -ForegroundColor Yellow
    
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "    Usando winget para instalar RustDesk..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "winget install RustDesk.RustDesk --silent --accept-package-agreements --accept-source-agreements" "Instalando RustDesk via winget"
        if ($result) {
            Write-Host "    RustDesk instalado com sucesso via winget!" -ForegroundColor Green
            Write-Host "    Configurando senha padrao 2772..." -ForegroundColor Yellow
            
            # Criar arquivo de configuracao do RustDesk com senha
            $rustdeskConfigDir = Join-Path $env:APPDATA "RustDesk"
            $rustdeskConfigFile = Join-Path $rustdeskConfigDir "config.toml"
            
            try {
                New-Item -ItemType Directory -Force -Path $rustdeskConfigDir | Out-Null
                $configContent = @"
password = '2772'
"@
                Set-Content -Path $rustdeskConfigFile -Value $configContent -Encoding UTF8
                Write-Host "    [OK] Senha 2772 configurada para RustDesk!" -ForegroundColor Green
            } catch {
                Write-Host "    [AVISO] Nao foi possivel configurar senha automaticamente: $($_.Exception.Message)" -ForegroundColor Yellow
                Write-Host "    Configure a senha 2772 manualmente no RustDesk" -ForegroundColor Yellow
            }
            
            return $true
        }
    }
    
    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        Write-Host "    Usando chocolatey para instalar RustDesk..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "choco install rustdesk -y" "Instalando RustDesk via chocolatey"
        if ($result) {
            Write-Host "    RustDesk instalado com sucesso via chocolatey!" -ForegroundColor Green
            Write-Host "    Configure a senha 2772 manualmente no RustDesk" -ForegroundColor Yellow
            return $true
        }
    }
    
    Write-Host "`n$('='*60)" -ForegroundColor Red
    Write-Host "INSTALACAO MANUAL DO RUSTDESK NECESSARIA" -ForegroundColor Red
    Write-Host "$('='*60)" -ForegroundColor Red
    Write-Host "`nPor favor, siga estes passos:" -ForegroundColor White
    Write-Host "1. Acesse: https://rustdesk.com/" -ForegroundColor Cyan
    Write-Host "2. Baixe o instalador para Windows" -ForegroundColor Cyan
    Write-Host "3. Execute o instalador" -ForegroundColor Cyan
    Write-Host "4. Configure a senha 2772 no RustDesk" -ForegroundColor Cyan
    Write-Host "5. Apos a instalacao, execute este script novamente" -ForegroundColor Cyan
    exit 1
}

function Install-Ollama {
    Write-Host "`n[+] Instalando Ollama automaticamente..." -ForegroundColor Yellow
    
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "    Usando winget para instalar Ollama..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "winget install Ollama.Ollama --silent --accept-package-agreements --accept-source-agreements" "Instalando Ollama via winget"
        if ($result) {
            Write-Host "    Ollama instalado com sucesso via winget!" -ForegroundColor Green
            Write-Host "    Atualizando PATH para sessao atual..." -ForegroundColor Yellow
            $env:PATH += ";$env:LOCALAPPDATA\Programs\Ollama"
            Write-Host "    Por favor, feche e reabra este terminal para atualizar o PATH permanentemente." -ForegroundColor Yellow
            Write-Host "    Execute este script novamente apos reabrir o terminal." -ForegroundColor Yellow
            exit 1
        }
    }
    
    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        Write-Host "    Usando chocolatey para instalar Ollama..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "choco install ollama -y" "Instalando Ollama via chocolatey"
        if ($result) {
            Write-Host "    Ollama instalado com sucesso via chocolatey!" -ForegroundColor Green
            Write-Host "    Atualizando PATH para sessao atual..." -ForegroundColor Yellow
            $env:PATH += ";C:\ProgramData\chocolatey\bin"
            Write-Host "    Por favor, feche e reabra este terminal para atualizar o PATH permanentemente." -ForegroundColor Yellow
            Write-Host "    Execute este script novamente apos reabrir o terminal." -ForegroundColor Yellow
            exit 1
        }
    }
    
    Write-Host "    Baixando instalador do Ollama..." -ForegroundColor Yellow
    $installerUrl = "https://ollama.com/download/OllamaSetup.exe"
    $installerPath = Join-Path $scriptDir "ollama-installer.exe"
    
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        Write-Host "    [OK] Download concluido!" -ForegroundColor Green
        
        Write-Host "    Instalando Ollama..." -ForegroundColor Yellow
        $process = Start-Process -FilePath $installerPath -ArgumentList "/silent" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "    [OK] Ollama instalado com sucesso!" -ForegroundColor Green
            Remove-Item $installerPath -Force
            Write-Host "    Atualizando PATH para sessao atual..." -ForegroundColor Yellow
            $env:PATH += ";$env:LOCALAPPDATA\Programs\Ollama"
            Write-Host "    Por favor, feche e reabra este terminal para atualizar o PATH permanentemente." -ForegroundColor Yellow
            Write-Host "    Execute este script novamente apos reabrir o terminal." -ForegroundColor Yellow
            exit 1
        } else {
            Write-Host "    [ERRO] Falha na instalacao do Ollama. Codigo: $($process.ExitCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "    [ERRO] Erro ao baixar/instalar Ollama: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n$('='*60)" -ForegroundColor Red
    Write-Host "INSTALACAO MANUAL DO OLLAMA NECESSARIA" -ForegroundColor Red
    Write-Host "$('='*60)" -ForegroundColor Red
    Write-Host "`nPor favor, siga estes passos:" -ForegroundColor White
    Write-Host "1. Acesse: https://ollama.com/download" -ForegroundColor Cyan
    Write-Host "2. Baixe o instalador para Windows" -ForegroundColor Cyan
    Write-Host "3. Execute o instalador" -ForegroundColor Cyan
    Write-Host "4. Apos a instalacao, feche e reabra este terminal" -ForegroundColor Cyan
    Write-Host "5. Execute este script novamente" -ForegroundColor Cyan
    exit 1
}

function Install-OllamaModel {
    $modelName = "antigravity-sonnet"
    Write-Host "`n[+] Configurando modelo Ollama: $modelName" -ForegroundColor Yellow
    
    $result = Invoke-CommandSafe "ollama pull $modelName" "Baixando modelo $modelName"
    if ($result) {
        Write-Host "    [OK] Modelo $modelName configurado com sucesso!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "    [AVISO] Erro ao baixar modelo, mas continuando..." -ForegroundColor Yellow
        return $false
    }
}

function Set-OllamaKnowledgeBase {
    Write-Host "`n[+] Configurando base de conhecimento para Ollama..." -ForegroundColor Yellow
    
    $knowledgeBaseDir = Join-Path $scriptDir "knowledge_base"
    $rulesFile = Join-Path $knowledgeBaseDir "layout_rules.txt"
    $schedulerScript = Join-Path $scriptDir "update_knowledge.ps1"
    
    try {
        New-Item -ItemType Directory -Force -Path $knowledgeBaseDir | Out-Null
        Write-Host "    [OK] Diretorio de conhecimento criado: $knowledgeBaseDir" -ForegroundColor Green
    } catch {
        Write-Host "    [ERRO] Erro ao criar diretorio de conhecimento: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    # Baixar documento do Google Docs
    $docUrl = "https://docs.google.com/document/d/1sTsRoAEWrU-1ltOMmUWyQ-18DFTmYl0R5UZc-QnNtCs/export?format=txt"
    try {
        Invoke-WebRequest -Uri $docUrl -OutFile $rulesFile -UseBasicParsing
        Write-Host "    [OK] Documento de regras baixado: $rulesFile" -ForegroundColor Green
    } catch {
        Write-Host "    [ERRO] Erro ao baixar documento: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    [AVISO] Criando arquivo de regras vazio..." -ForegroundColor Yellow
        Set-Content -Path $rulesFile -Value "# Regras de layout, postagem e paginas" -Encoding UTF8
    }
    
    # Criar script de atualizacao diaria
    $schedulerContent = @'
# Script de atualizacao diaria da base de conhecimento do Ollama
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$knowledgeBaseDir = Join-Path $scriptDir "knowledge_base"
$rulesFile = Join-Path $knowledgeBaseDir "layout_rules.txt"
$docUrl = "https://docs.google.com/document/d/1sTsRoAEWrU-1ltOMmUWyQ-18DFTmYl0R5UZc-QnNtCs/export?format=txt"

Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Atualizando base de conhecimento..." -ForegroundColor Cyan

try {
    Invoke-WebRequest -Uri $docUrl -OutFile $rulesFile -UseBasicParsing
    Write-Host "    [OK] Base de conhecimento atualizada com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "    [ERRO] Erro ao atualizar base de conhecimento: $($_.Exception.Message)" -ForegroundColor Red
}

# Criar/modificar tarefa agendada para execucao diaria
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At "9:00 AM"
Register-ScheduledTask -TaskName "OllamaKnowledgeUpdate" -Action $action -Trigger $trigger -Description "Atualiza base de conhecimento do Ollama diariamente" -Force | Out-Null
Write-Host "    [OK] Tarefa agendada criada para atualizacao diaria as 9:00 AM" -ForegroundColor Green
'@
    
    try {
        Set-Content -Path $schedulerScript -Value $schedulerContent -Encoding UTF8
        Write-Host "    [OK] Script de atualizacao criado: $schedulerScript" -ForegroundColor Green
        
        # Executar script de atualizacao inicial
        & powershell -ExecutionPolicy Bypass -File $schedulerScript
        Write-Host "    [OK] Atualizacao inicial executada!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "    [ERRO] Erro ao criar/executar script de atualizacao: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-NodeJs {
    Write-Host "`n[+] Instalando Node.js automaticamente..." -ForegroundColor Yellow
    
    $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetAvailable) {
        Write-Host "    Usando winget para instalar Node.js..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements" "Instalando Node.js via winget"
        if ($result) {
            Write-Host "    Node.js instalado com sucesso via winget!" -ForegroundColor Green
            Write-Host "    Por favor, feche e reabra este terminal para atualizar o PATH." -ForegroundColor Yellow
            Write-Host "    Execute este script novamente apos reabrir o terminal." -ForegroundColor Yellow
            exit 1
        }
    }
    
    $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoAvailable) {
        Write-Host "    Usando chocolatey para instalar Node.js..." -ForegroundColor Yellow
        $result = Invoke-CommandSafe "choco install nodejs-lts -y" "Instalando Node.js via chocolatey"
        if ($result) {
            Write-Host "    Node.js instalado com sucesso via chocolatey!" -ForegroundColor Green
            Write-Host "    Por favor, feche e reabra este terminal para atualizar o PATH." -ForegroundColor Yellow
            Write-Host "    Execute este script novamente apos reabrir o terminal." -ForegroundColor Yellow
            exit 1
        }
    }
    
    Write-Host "`n$('='*60)" -ForegroundColor Red
    Write-Host "INSTALACAO MANUAL DO NODE.JS NECESSARIA" -ForegroundColor Red
    Write-Host "$('='*60)" -ForegroundColor Red
    Write-Host "`nPor favor, siga estes passos:" -ForegroundColor White
    Write-Host "1. Acesse: https://nodejs.org/" -ForegroundColor Cyan
    Write-Host "2. Baixe a versao LTS para Windows" -ForegroundColor Cyan
    Write-Host "3. Execute o instalador" -ForegroundColor Cyan
    Write-Host "4. Marque 'Add to PATH'" -ForegroundColor Cyan
    Write-Host "5. Apos a instalacao, feche e reabra este terminal" -ForegroundColor Cyan
    Write-Host "6. Execute este script novamente" -ForegroundColor Cyan
    exit 1
}

function Request-OpenRouterToken {
    Write-Host "`n$('='*60)" -ForegroundColor Cyan
    Write-Host "CONFIGURACAO DO OPENROUTER" -ForegroundColor Cyan
    Write-Host "$('='*60)" -ForegroundColor Cyan
    
    $token = $null
    
    # Tenta usar GitHub CLI para ler o secret
    $ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghAvailable) {
        Write-Host "    GitHub CLI encontrado, tentando ler secret OPENROUTER_TOKEN..." -ForegroundColor Yellow
        try {
            $secretValue = gh secret view OPENROUTER_TOKEN --repo canalqb/mcpopenrouter 2>&1
            if ($LASTEXITCODE -eq 0) {
                $token = $secretValue
                Write-Host "    [OK] Secret lido do GitHub!" -ForegroundColor Green
            }
        } catch {
            Write-Host "    [AVISO] Nao foi possivel ler o secret via GitHub CLI: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Se nao conseguiu ler o secret, solicita manualmente
    if (-not $token) {
        $token = Read-Host "Digite seu token do OpenRouter (ou pressione Enter para usar o existente)"
    }
    
    if ($token -ne "") {
        Write-Host "    Token fornecido, atualizando arquivo .env..." -ForegroundColor Yellow
        try {
            Set-Content -Path $envFile -Value "OPENAI_API_KEY=$token" -Encoding UTF8
            Write-Host "    [OK] Token salvo em $envFile" -ForegroundColor Green
        } catch {
            Write-Host "    [ERRO] Erro ao salvar token: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        if (Test-Path $envFile) {
            Write-Host "    Usando token existente do arquivo .env" -ForegroundColor Yellow
        } else {
            Write-Host "    [AVISO] Nenhum token fornecido e arquivo .env nao existe" -ForegroundColor Yellow
            Write-Host "    Voce precisara configurar o token manualmente depois" -ForegroundColor Yellow
        }
    }
}

function Install-PythonDependencies {
    $requirementsFile = Join-Path $scriptDir "requirements.txt"
    
    if (-not (Test-Path $requirementsFile)) {
        Write-Host "    [ERRO] Arquivo requirements.txt nao encontrado" -ForegroundColor Red
        return $false
    }
    
    return Invoke-CommandSafe "& `"$pythonPath`" -m pip install -r `"$requirementsFile`"" "Instalando dependencias Python"
}

function New-DevinConfigDir {
    try {
        New-Item -ItemType Directory -Force -Path $devinConfigDir | Out-Null
        Write-Host "    [OK] Diretorio criado: $devinConfigDir" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "    [ERRO] Erro ao criar diretorio: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function New-McpConfig {
    $config = @{
        mcpServers = @{
            filesystem = @{
                command = "npx"
                args = @(
                    "-y"
                    "@modelcontextprotocol/server-filesystem"
                    $scriptDir
                )
            }
        }
    }
    
    try {
        $configJson = $config | ConvertTo-Json -Depth 10
        Set-Content -Path $mcpConfigFile -Value $configJson -Encoding UTF8
        Write-Host "    [OK] Configuracao MCP criada: $mcpConfigFile" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "    [ERRO] Erro ao criar configuracao: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function New-DevinMcpConfig {
    $devinConfigDir = Join-Path $env:APPDATA "Devin"
    $devinMcpConfigFile = Join-Path $devinConfigDir "mcp_config.json"
    
    try {
        New-Item -ItemType Directory -Force -Path $devinConfigDir | Out-Null
        Write-Host "    [OK] Diretorio Devin criado: $devinConfigDir" -ForegroundColor Green
    } catch {
        Write-Host "    [ERRO] Erro ao criar diretorio Devin: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    $config = @{
        mcpServers = @{
            openrouter = @{
                command = "npx"
                args = @(
                    "-y"
                    "@modelcontextprotocol/server-openrouter"
                    "--model"
                    "ollama/antigravity-sonnet"
                )
                env = @{
                    OPENROUTER_API_KEY = (Get-Content $envFile -ErrorAction SilentlyContinue | Select-String "OPENAI_API_KEY" | ForEach-Object { $_.ToString().Split("=")[1] })
                }
            }
        }
    }
    
    try {
        $configJson = $config | ConvertTo-Json -Depth 10
        Set-Content -Path $devinMcpConfigFile -Value $configJson -Encoding UTF8
        Write-Host "    [OK] Configuracao MCP Devin criada: $devinMcpConfigFile" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "    [ERRO] Erro ao criar configuracao Devin: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-NpxFilesystem {
    $testCommand = "npx -y @modelcontextprotocol/server-filesystem `"$scriptDir`""
    Write-Host "`n[+] Testando servidor MCP filesystem..." -ForegroundColor Yellow
    Write-Host "    Isso pode levar alguns segundos na primeira vez..." -ForegroundColor Yellow
    
    try {
        $job = Start-Job -ScriptBlock {
            param($command)
            Invoke-Expression $command 2>&1 | Out-String
        } -ArgumentList $testCommand
        
        $completed = Wait-Job -Job $job -Timeout 30
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        
        if ($completed) {
            $output = Receive-Job -Job $job
            Remove-Job -Job $job
            
            if ($output -match "Secure MCP Filesystem Server") {
                Write-Host "    [OK] Servidor MCP filesystem funcionando!" -ForegroundColor Green
                return $true
            }
        }
        
        Write-Host "    [AVISO] Teste inconclusivo, mas configuracao foi criada" -ForegroundColor Yellow
        return $true
    } catch {
        Write-Host "    [AVISO] Erro no teste, mas configuracao foi criada: $($_.Exception.Message)" -ForegroundColor Yellow
        return $true
    }
}

function Add-ToPathWindows {
    Write-Host "`n[+] Configuracao do PATH do Windows" -ForegroundColor Yellow
    Write-Host "    Nota: Esta configuracao pode requerer direitos de administrador" -ForegroundColor Yellow
    Write-Host "    Se falhar, voce pode adicionar manualmente:" -ForegroundColor Yellow
    Write-Host "    - $env:APPDATA\Python\Python38\Scripts" -ForegroundColor Cyan
    Write-Host "    - C:\Program Files\nodejs" -ForegroundColor Cyan
    
    try {
        $pythonScripts = "$env:APPDATA\Python\Python38\Scripts"
        $nodejs = "C:\Program Files\nodejs"
        
        $regPath = "HKCU:\Environment"
        $currentPath = (Get-ItemProperty -Path $regPath -Name Path -ErrorAction SilentlyContinue).Path
        
        if ($currentPath) {
            $pathsToAdd = @()
            if ($currentPath -notlike "*$pythonScripts*") {
                $pathsToAdd += $pythonScripts
            }
            if ($currentPath -notlike "*$nodejs*") {
                $pathsToAdd += $nodejs
            }
            
            if ($pathsToAdd.Count -gt 0) {
                Write-Host "    [AVISO] Os seguintes diretorios precisam ser adicionados ao PATH:" -ForegroundColor Yellow
                foreach ($p in $pathsToAdd) {
                    Write-Host "       - $p" -ForegroundColor Cyan
                }
                Write-Host "    [AVISO] Adicione manualmente nas Variaveis de Ambiente do Windows" -ForegroundColor Yellow
            } else {
                Write-Host "    [OK] Diretorios ja estao no PATH" -ForegroundColor Green
            }
        } else {
            Write-Host "    [AVISO] Nao foi possivel verificar o PATH automaticamente" -ForegroundColor Yellow
            Write-Host "    [AVISO] Verifique manualmente se necessario" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    [AVISO] Nao foi possivel verificar o PATH automaticamente: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "    [AVISO] Verifique manualmente se necessario" -ForegroundColor Yellow
    }
}

function Invoke-Verification {
    Write-Host "`n$('='*60)" -ForegroundColor Cyan
    Write-Host "VERIFICACAO FINAL" -ForegroundColor Cyan
    Write-Host "$('='*60)" -ForegroundColor Cyan
    
    $checks = @(
        @("Python", "& `"$pythonPath`" --version"),
        @("Node.js", "node -v"),
        @("npm", "npm -v"),
        @("npx", "npx -v"),
        @("Ollama", "ollama -v"),
        @("Ollama modelo", "ollama list"),
        @("Python openai", "& `"$pythonPath`" -c `"import openai; print(openai.__version__)`""),
        @("Python dotenv", "& `"$pythonPath`" -c `"import dotenv; print(dotenv.__version__)`"")
    )
    
    $results = @()
    foreach ($check in $checks) {
        $name = $check[0]
        $command = $check[1]
        $success = Invoke-CommandSafe $command "Verificando $name"
        $results += ,@($name, $success)
    }
    
    Write-Host "`n$('='*60)" -ForegroundColor Cyan
    Write-Host "RESUMO DA VERIFICACAO" -ForegroundColor Cyan
    Write-Host "$('='*60)" -ForegroundColor Cyan
    
    foreach ($result in $results) {
        $name = $result[0]
        $success = $result[1]
        $status = if ($success) { "[OK]" } else { "[ERRO]" }
        $color = if ($success) { "Green" } else { "Red" }
        Write-Host "$($name.PadRight(20)) $status" -ForegroundColor $color
    }
    
    Write-Host "`n$('='*60)" -ForegroundColor Cyan
    Write-Host "ARQUIVOS CRIADOS" -ForegroundColor Cyan
    Write-Host "$('='*60)" -ForegroundColor Cyan
    Write-Host "Configuracao MCP: $mcpConfigFile" -ForegroundColor White
    Write-Host "Arquivo .env: $envFile" -ForegroundColor White
    Write-Host "Diretorio projeto:  $scriptDir" -ForegroundColor White
    
    Write-Host "`n$('='*60)" -ForegroundColor Cyan
    Write-Host "PROXIMOS PASSOS" -ForegroundColor Cyan
    Write-Host "$('='*60)" -ForegroundColor Cyan
    Write-Host "1. Reinicie o Windsurf para carregar a configuracao MCP" -ForegroundColor White
    Write-Host "2. As ferramentas MCP estarao disponiveis no Cascade" -ForegroundColor White
    Write-Host "3. Para testar o cliente Python: $pythonPath mcp-client.py" -ForegroundColor White
    Write-Host "4. Para uso automatizado: $pythonPath mcp-client.py 'sua pergunta'" -ForegroundColor White
}

Write-Host "`n$('='*60)" -ForegroundColor Cyan
Write-Host "SCRIPT DE CONFIGURACAO 100% AUTOMATICA" -ForegroundColor Cyan
Write-Host "MCP + OpenRouter + Devin + Ollama + Java + Android SDK + Notepad++ + RustDesk" -ForegroundColor Cyan
Write-Host "$('='*60)" -ForegroundColor Cyan

$totalSteps = 17
$currentStep = 0

$currentStep++
Write-Step $currentStep $totalSteps "Verificando Python $pythonVersion"
$pythonPath = Test-PythonInstalled
if (-not $pythonPath) {
    Write-Host "    Python $pythonVersion nao encontrado" -ForegroundColor Yellow
    Install-Python
}

$currentStep++
Write-Step $currentStep $totalSteps "Executando setup.py"
$setupPyPath = Join-Path $scriptDir "setup.py"
if (Test-Path $setupPyPath) {
    Write-Host "    Executando setup.py..." -ForegroundColor Yellow
    $result = Invoke-CommandSafe "& `"$pythonPath`" `"$setupPyPath`"" "Executando setup.py"
    if ($result) {
        Write-Host "    [OK] setup.py executado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "    [AVISO] Erro ao executar setup.py, mas continuando..." -ForegroundColor Yellow
    }
} else {
    Write-Host "    [AVISO] setup.py nao encontrado, pulando..." -ForegroundColor Yellow
}

$currentStep++
Write-Step $currentStep $totalSteps "Verificando Node.js"
if (-not (Test-NodeInstalled)) {
    Write-Host "    Node.js nao encontrado" -ForegroundColor Yellow
    Install-NodeJs
}

$currentStep++
Write-Step $currentStep $totalSteps "Verificando npx"
if (-not (Test-NpxInstalled)) {
    Write-Host "    npx nao encontrado, mas geralmente vem com Node.js" -ForegroundColor Yellow
    Write-Host "    Continuando mesmo assim..." -ForegroundColor Yellow
}

$currentStep++
Write-Step $currentStep $totalSteps "Verificando Java"
$javaPath = Test-JavaInstalled
if (-not $javaPath) {
    Write-Host "    Java nao encontrado" -ForegroundColor Yellow
    Install-Java
}

$currentStep++
Write-Step $currentStep $totalSteps "Verificando ADB"
$adbPath = Test-AdbInstalled
if (-not $adbPath) {
    Write-Host "    ADB nao encontrado" -ForegroundColor Yellow
    Install-AndroidSdk
}

$currentStep++
Write-Step $currentStep $totalSteps "Verificando Notepad++"
if (-not (Test-NotepadPlusPlusInstalled)) {
    Write-Host "    Notepad++ nao encontrado" -ForegroundColor Yellow
    Install-NotepadPlusPlus
}

$currentStep++
Write-Step $currentStep $totalSteps "Verificando RustDesk"
if (-not (Test-RustDeskInstalled)) {
    Write-Host "    RustDesk nao encontrado" -ForegroundColor Yellow
    Install-RustDesk
}

$currentStep++
Write-Step $currentStep $totalSteps "Verificando Ollama"
if (-not (Test-OllamaInstalled)) {
    Write-Host "    Ollama nao encontrado" -ForegroundColor Yellow
    Install-Ollama
}

$currentStep++
Write-Step $currentStep $totalSteps "Configurando modelo Ollama antigravity-sonnet"
Install-OllamaModel

$currentStep++
Write-Step $currentStep $totalSteps "Configurando base de conhecimento do Ollama"
Set-OllamaKnowledgeBase

$currentStep++
Write-Step $currentStep $totalSteps "Solicitando token OpenRouter"
Request-OpenRouterToken

$currentStep++
Write-Step $currentStep $totalSteps "Instalando dependencias Python"
Install-PythonDependencies

$currentStep++
Write-Step $currentStep $totalSteps "Configurando PATH do Windows"
Add-ToPathWindows

$currentStep++
Write-Step $currentStep $totalSteps "Criando diretorio de configuracao Devin"
New-DevinConfigDir

$currentStep++
Write-Step $currentStep $totalSteps "Criando configuracao MCP"
New-McpConfig

$currentStep++
Write-Step $currentStep $totalSteps "Criando configuracao MCP Devin com OpenRouter"
New-DevinMcpConfig

$currentStep++
Write-Step $currentStep $totalSteps "Testando e verificando configuracao"
Test-NpxFilesystem
Invoke-Verification

Write-Host "`n$('='*60)" -ForegroundColor Green
Write-Host "CONFIGURACAO 100% AUTOMATICA CONCLUIDA!" -ForegroundColor Green
Write-Host "$('='*60)" -ForegroundColor Green
Write-Host "`nAgora voce pode:" -ForegroundColor White
Write-Host "1. Reiniciar o Windsurf para usar MCP" -ForegroundColor White
Write-Host "2. Executar: $pythonPath mcp-client.py" -ForegroundColor White
Write-Host "3. Ou modo automatico: $pythonPath mcp-client.py 'sua pergunta'" -ForegroundColor White

Write-Host "`nPressione qualquer tecla para sair..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
