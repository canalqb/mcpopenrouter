@echo off
chcp 65001 >nul
echo ============================================================
echo SCRIPT DE CONFIGURAÇÃO AUTOMATIZADA
echo MCP + OpenRouter + Windsurf
echo ============================================================
echo.

cd /d "%~dp0"

"C:\Program Files\Python38\python.exe" setup.py

echo.
echo ============================================================
echo Pressione qualquer tecla para sair...
pause >nul
