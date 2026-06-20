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
