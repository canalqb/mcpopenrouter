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
