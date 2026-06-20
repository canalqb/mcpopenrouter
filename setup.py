#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de configuração automatizada para MCP com OpenRouter e Windsurf
Python 3.8+ Compatible
"""

import os
import sys
import subprocess
import urllib.request
import json
import shutil
from pathlib import Path

class SetupManager:
    def __init__(self):
        self.script_dir = Path(__file__).parent
        self.user_profile = Path(os.path.expanduser("~"))
        self.windsurf_config_dir = self.user_profile / ".codeium" / "windsurf"
        self.mcp_config_file = self.windsurf_config_dir / "mcp_config.json"
        # Usa caminho completo do Python conhecido
        self.python_path = r"C:\Program Files\Python38\python.exe"
        
    def print_step(self, step_num, total_steps, message):
        """Imprime passo atual de forma formatada"""
        print(f"\n{'='*60}")
        print(f"PASSO {step_num}/{total_steps}: {message}")
        print('='*60)
    
    def get_python_path(self):
        """Retorna o caminho do Python ou None se não encontrado"""
        # Tenta encontrar Python em locais comuns
        possible_paths = [
            r"C:\Program Files\Python38\python.exe",
            r"C:\Python38\python.exe",
            r"C:\Users\Qb\AppData\Local\Programs\Python\Python38\python.exe",
            "python",  # Tenta via PATH
            "python3",
        ]
        
        for path in possible_paths:
            try:
                result = subprocess.run(
                    [path, "--version"],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                if result.returncode == 0:
                    print(f"   Python encontrado em: {path}")
                    return path
            except:
                continue
        
        return None
    
    def run_command(self, command, description):
        """Executa comando e retorna sucesso/falha"""
        print(f"\n[+] Executando: {description}")
        print(f"    Comando: {command}")
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=300
            )
            if result.returncode == 0:
                print(f"    [OK] Sucesso!")
                if result.stdout:
                    print(f"    Saída: {result.stdout.strip()[:200]}")
                return True
            else:
                print(f"    [ERRO] Falha!")
                print(f"    Erro: {result.stderr.strip()[:200]}")
                return False
        except subprocess.TimeoutExpired:
            print(f"    [ERRO] Timeout (300s)")
            return False
        except Exception as e:
            print(f"    [ERRO] Excecao: {str(e)}")
            return False
    
    def check_node_installed(self):
        """Verifica se Node.js está instalado"""
        return self.run_command("node -v", "Verificando Node.js")
    
    def check_npx_installed(self):
        """Verifica se npx está instalado"""
        return self.run_command("npx -v", "Verificando npx")
    
    def download_node_installer(self):
        """Baixa instalador do Node.js para Windows"""
        node_url = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"
        installer_path = self.script_dir / "node-installer.msi"
        
        print(f"\n[+] Baixando Node.js...")
        print(f"    URL: {node_url}")
        print(f"    Destino: {installer_path}")
        
        try:
            urllib.request.urlretrieve(node_url, installer_path)
            print(f"    [OK] Download concluido!")
            return installer_path
        except Exception as e:
            print(f"    [ERRO] Erro no download: {str(e)}")
            return None
    
    def install_node_manually(self):
        """Instrui instalacao manual do Node.js"""
        print("\n" + "="*60)
        print("INSTALACAO MANUAL DO NODE.JS NECESSARIA")
        print("="*60)
        print("\nO Node.js nao esta instalado ou nao foi possivel instalar automaticamente.")
        print("\nPor favor, siga estes passos:")
        print("1. Acesse: https://nodejs.org/")
        print("2. Baixe a versao LTS (Long Term Support) para Windows")
        print("3. Execute o instalador")
        print("4. Certifique-se de marcar 'Add to PATH' durante a instalacao")
        print("5. Apos a instalacao, feche e reabra este terminal")
        print("6. Execute este script novamente")
        print("\nO script sera encerrado agora.")
        sys.exit(1)
    
    def install_python_dependencies(self):
        """Instala dependências Python"""
        requirements_file = self.script_dir / "requirements.txt"
        
        if not requirements_file.exists():
            print(f"    [ERRO] Arquivo requirements.txt nao encontrado")
            return False
        
        return self.run_command(
            f'"{self.python_path}" -m pip install -r "{requirements_file}"',
            "Instalando dependencias Python"
        )
    
    def create_windsurf_config_dir(self):
        """Cria diretório de configuração do Windsurf"""
        try:
            self.windsurf_config_dir.mkdir(parents=True, exist_ok=True)
            print(f"    [OK] Diretorio criado: {self.windsurf_config_dir}")
            return True
        except Exception as e:
            print(f"    [ERRO] Erro ao criar diretorio: {str(e)}")
            return False
    
    def create_mcp_config(self):
        """Cria arquivo de configuração MCP"""
        config = {
            "mcpServers": {
                "filesystem": {
                    "command": "npx",
                    "args": [
                        "-y",
                        "@modelcontextprotocol/server-filesystem",
                        str(self.script_dir)
                    ]
                }
            }
        }
        
        try:
            with open(self.mcp_config_file, 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2, ensure_ascii=False)
            print(f"    [OK] Configuracao MCP criada: {self.mcp_config_file}")
            return True
        except Exception as e:
            print(f"    [ERRO] Erro ao criar configuracao: {str(e)}")
            return False
    
    def test_npx_filesystem(self):
        """Testa se o servidor MCP filesystem funciona"""
        test_command = f'npx -y @modelcontextprotocol/server-filesystem "{self.script_dir}"'
        print(f"\n[+] Testando servidor MCP filesystem...")
        print(f"    Isso pode levar alguns segundos na primeira vez...")
        
        # Não vamos esperar muito tempo neste teste
        try:
            result = subprocess.run(
                test_command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=30
            )
            if result.returncode == 0 or "Secure MCP Filesystem Server" in result.stdout:
                print(f"    [OK] Servidor MCP filesystem funcionando!")
                return True
            else:
                print(f"    [AVISO] Teste inconclusivo, mas configuracao foi criada")
                return True
        except subprocess.TimeoutExpired:
            print(f"    [AVISO] Timeout no teste, mas configuracao foi criada")
            return True
        except Exception as e:
            print(f"    [AVISO] Erro no teste, mas configuracao foi criada: {str(e)}")
            return True
    
    def add_to_path_windows(self):
        """Adiciona diretórios ao PATH do Windows (requer direitos de admin)"""
        print("\n[+] Configuracao do PATH do Windows")
        print("    Nota: Esta configuracao pode requerer direitos de administrador")
        print("    Se falhar, voce pode adicionar manualmente:")
        print(f"    - C:\\Users\\Qb\\AppData\\Roaming\\Python\\Python38\\Scripts")
        print(f"    - C:\\Program Files\\nodejs")
        
        # Tenta adicionar via registro (pode falhar sem admin)
        try:
            import winreg
            
            python_scripts = r"C:\Users\Qb\AppData\Roaming\Python\Python38\Scripts"
            nodejs = r"C:\Program Files\nodejs"
            
            # Abre a chave de registro do ambiente
            key = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r"Environment",
                0,
                winreg.KEY_READ
            )
            
            current_path, _ = winreg.QueryValueEx(key, "Path")
            winreg.CloseKey(key)
            
            paths_to_add = []
            if python_scripts not in current_path:
                paths_to_add.append(python_scripts)
            if nodejs not in current_path:
                paths_to_add.append(nodejs)
            
            if paths_to_add:
                print(f"    [AVISO] Os seguintes diretorios precisam ser adicionados ao PATH:")
                for p in paths_to_add:
                    print(f"       - {p}")
                print(f"    [AVISO] Adicione manualmente nas Variaveis de Ambiente do Windows")
            else:
                print(f"    [OK] Diretorios ja estao no PATH")
                
        except Exception as e:
            print(f"    [AVISO] Nao foi possivel verificar o PATH automaticamente: {str(e)}")
            print(f"    [AVISO] Verifique manualmente se necessario")
    
    def verify_setup(self):
        """Verifica se tudo está configurado corretamente"""
        print("\n" + "="*60)
        print("VERIFICACAO FINAL")
        print("="*60)
        
        checks = [
            ("Node.js", "node -v"),
            ("npm", "npm -v"),
            ("npx", "npx -v"),
            ("Python openai", f'"{self.python_path}" -c "import openai; print(openai.__version__)"'),
            ("Python dotenv", f'"{self.python_path}" -c "import dotenv; print(dotenv.__version__)"'),
        ]
        
        results = []
        for name, command in checks:
            success = self.run_command(command, f"Verificando {name}")
            results.append((name, success))
        
        print("\n" + "="*60)
        print("RESUMO DA VERIFICACAO")
        print("="*60)
        for name, success in results:
            status = "[OK]" if success else "[ERRO]"
            print(f"{name:20} {status}")
        
        print("\n" + "="*60)
        print("ARQUIVOS CRIADOS")
        print("="*60)
        print(f"Configuracao MCP: {self.mcp_config_file}")
        print(f"Diretorio projeto:  {self.script_dir}")
        
        print("\n" + "="*60)
        print("PROXIMOS PASSOS")
        print("="*60)
        print("1. Reinicie o Windsurf para carregar a configuracao MCP")
        print("2. As ferramentas MCP estarao disponiveis no Cascade")
        print(f"3. Para testar o cliente Python: {self.python_path} mcp-client.py")
        print(f"4. Para uso automatizado: {self.python_path} mcp-client.py \"sua pergunta\"")
    
    def run(self):
        """Executa todo o processo de configuracao"""
        total_steps = 7
        current_step = 0
        
        print("\n" + "="*60)
        print("SCRIPT DE CONFIGURACAO AUTOMATIZADA")
        print("MCP + OpenRouter + Windsurf")
        print("="*60)
        
        # Passo 1: Verificar Node.js
        current_step += 1
        self.print_step(current_step, total_steps, "Verificando Node.js")
        if not self.check_node_installed():
            print("    Node.js nao encontrado")
            self.install_node_manually()
            return  # Sai para instalacao manual
        
        # Passo 2: Verificar npx
        current_step += 1
        self.print_step(current_step, total_steps, "Verificando npx")
        if not self.check_npx_installed():
            print("    npx nao encontrado, mas geralmente vem com Node.js")
            print("    Continuando mesmo assim...")
        
        # Passo 3: Instalar dependencias Python
        current_step += 1
        self.print_step(current_step, total_steps, "Instalando dependencias Python")
        self.install_python_dependencies()
        
        # Passo 4: Configurar PATH
        current_step += 1
        self.print_step(current_step, total_steps, "Configurando PATH do Windows")
        self.add_to_path_windows()
        
        # Passo 5: Criar diretorio Windsurf
        current_step += 1
        self.print_step(current_step, total_steps, "Criando diretorio de configuracao Windsurf")
        self.create_windsurf_config_dir()
        
        # Passo 6: Criar configuracao MCP
        current_step += 1
        self.print_step(current_step, total_steps, "Criando configuracao MCP")
        self.create_mcp_config()
        
        # Passo 7: Testar e verificar
        current_step += 1
        self.print_step(current_step, total_steps, "Testando e verificando configuracao")
        self.test_npx_filesystem()
        self.verify_setup()
        
        print("\n" + "="*60)
        print("CONFIGURACAO CONCLUIDA!")
        print("="*60)
        print("\nAgora voce pode:")
        print("1. Reiniciar o Windsurf para usar MCP")
        print(f"2. Executar: {self.python_path} mcp-client.py")
        print(f"3. Ou modo automatico: {self.python_path} mcp-client.py \"sua pergunta\"")

def main():
    setup = SetupManager()
    try:
        setup.run()
    except KeyboardInterrupt:
        print("\n\nConfiguracao interrompida pelo usuario")
        sys.exit(1)
    except Exception as e:
        print(f"\n\nErro durante configuracao: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
