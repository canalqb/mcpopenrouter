import os
from openai import OpenAI
from dotenv import load_dotenv
import json

load_dotenv()  # load environment variables from .env

MODEL = "anthropic/claude-3.5-sonnet"

class SimpleOpenRouterClient:
    def __init__(self):
        self.openai = OpenAI(
            base_url="https://openrouter.ai/api/v1",
            api_key=os.getenv("OPENAI_API_KEY")
        )
        self.messages = []
    
    def define_tools(self):
        """Define available tools for file system operations"""
        tools = [
            {
                "type": "function",
                "function": {
                    "name": "read_file",
                    "description": "Read the contents of a file",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "path": {
                                "type": "string",
                                "description": "Path to the file to read"
                            }
                        },
                        "required": ["path"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "write_file",
                    "description": "Write content to a file",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "path": {
                                "type": "string",
                                "description": "Path to the file to write"
                            },
                            "content": {
                                "type": "string",
                                "description": "Content to write to the file"
                            }
                        },
                        "required": ["path", "content"]
                    }
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "list_directory",
                    "description": "List files and directories in a path",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "path": {
                                "type": "string",
                                "description": "Path to the directory to list"
                            }
                        },
                        "required": ["path"]
                    }
                }
            }
        ]
        return tools
    
    def execute_tool(self, tool_name, tool_args):
        """Execute a tool call"""
        try:
            if tool_name == "read_file":
                path = tool_args.get("path")
                with open(path, 'r', encoding='utf-8') as f:
                    return f.read()
            elif tool_name == "write_file":
                path = tool_args.get("path")
                content = tool_args.get("content")
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                return f"File written successfully to {path}"
            elif tool_name == "list_directory":
                path = tool_args.get("path")
                if not os.path.exists(path):
                    return f"Path {path} does not exist"
                items = os.listdir(path)
                return json.dumps(items, indent=2)
            else:
                return f"Unknown tool: {tool_name}"
        except Exception as e:
            return f"Error executing {tool_name}: {str(e)}"
    
    def process_query(self, query: str) -> str:
        """Process a user query"""
        self.messages.append({
            "role": "user",
            "content": query
        })
        
        available_tools = self.define_tools()
        
        response = self.openai.chat.completions.create(
            model=MODEL,
            tools=available_tools,
            messages=self.messages
        )
        
        self.messages.append(response.choices[0].message.model_dump())
        final_text = []
        content = response.choices[0].message
        
        if content.tool_calls is not None:
            for tool_call in content.tool_calls:
                tool_name = tool_call.function.name
                tool_args = json.loads(tool_call.function.arguments) if tool_call.function.arguments else {}
                
                # Execute tool call
                result = self.execute_tool(tool_name, tool_args)
                final_text.append(f"[Calling tool {tool_name} with args {tool_args}]")
                
                self.messages.append({
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "name": tool_name,
                    "content": result
                })
            
            # Get final response after tool execution
            response = self.openai.chat.completions.create(
                model=MODEL,
                max_tokens=1000,
                messages=self.messages,
            )
            final_text.append(response.choices[0].message.content)
            self.messages.append(response.choices[0].message.model_dump())
        else:
            final_text.append(content.content)
        
        return "\n".join(final_text)
    
    def chat_loop(self):
        """Run an interactive chat loop"""
        print("\n=== Cliente OpenRouter Iniciado ===")
        print("Ferramentas disponíveis: read_file, write_file, list_directory")
        print("Digite suas perguntas ou 'sair' para encerrar.")
        print("=====================================\n")
        
        while True:
            try:
                query = input("\nPergunta: ").strip()
                if query.lower() in ['sair', 'quit', 'exit', '']:
                    print("Encerrando...")
                    break
                result = self.process_query(query)
                print("\nResposta:")
                print(result)
                print("\n" + "="*50)
            except KeyboardInterrupt:
                print("\n\nEncerrando...")
                break
            except Exception as e:
                print(f"\nErro: {str(e)}")

def main():
    client = SimpleOpenRouterClient()
    
    # Modo automático: se passar argumento, executa e sai
    import sys
    if len(sys.argv) > 1:
        query = " ".join(sys.argv[1:])
        print(f"\n=== Executando comando automático ===")
        print(f"Pergunta: {query}\n")
        result = client.process_query(query)
        print("Resposta:")
        print(result)
    else:
        # Modo interativo
        client.chat_loop()

if __name__ == "__main__":
    main()
