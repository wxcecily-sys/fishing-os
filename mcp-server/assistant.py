#!/usr/bin/env python3
"""
Fishing OS - MCP AI 助手
基于 Ollama + MCP 协议
"""

import json
import subprocess
import os
import sys
from typing import Any, Dict, List, Optional

class FishingAssistant:
    def __init__(self, model: str = "qwen2.5:3b"):
        self.model = model
        self.ollama_url = "http://localhost:11434/api/generate"
        
    def check_ollama(self) -> bool:
        """检查 Ollama 服务状态"""
        try:
            result = subprocess.run(
                ["curl", "-s", "http://localhost:11434/api/tags"],
                capture_output=True, timeout=5
            )
            return result.returncode == 0
        except:
            return False
    
    def pull_model(self, model: str) -> Dict[str, Any]:
        """下载模型"""
        try:
            result = subprocess.run(
                ["ollama", "pull", model],
                capture_output=True, text=True
            )
            return {"success": True, "output": result.stdout}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def chat(self, message: str, system: str = "") -> str:
        """发送对话请求"""
        if not system:
            system = """你是一个运行在 Fishing OS 上的本地 AI 助手。
你可以帮助用户:
- 回答问题
- 写作和翻译
- 代码编写和调试
- 文件操作建议
- 系统使用帮助

请用中文回答，保持友好和专业。"""
        
        try:
            result = subprocess.run(
                ["ollama", "run", self.model, message],
                capture_output=True, text=True, timeout=60
            )
            return result.stdout if result.returncode == 0 else f"错误: {result.stderr}"
        except subprocess.TimeoutExpired:
            return "请求超时，请稍后重试"
        except Exception as e:
            return f"发生错误: {str(e)}"
    
    def mcp_tools(self) -> List[Dict[str, Any]]:
        """MCP 协议工具列表"""
        return [
            {
                "name": "search_web",
                "description": "联网搜索信息 (需要网络连接)",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string", "description": "搜索关键词"}
                    },
                    "required": ["query"]
                }
            },
            {
                "name": "run_command",
                "description": "在终端执行命令",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "command": {"type": "string", "description": "要执行的命令"}
                    },
                    "required": ["command"]
                }
            },
            {
                "name": "read_file",
                "description": "读取文件内容",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "path": {"type": "string", "description": "文件路径"}
                    },
                    "required": ["path"]
                }
            },
            {
                "name": "write_file",
                "description": "写入文件内容",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "path": {"type": "string", "description": "文件路径"},
                        "content": {"type": "string", "description": "文件内容"}
                    },
                    "required": ["path", "content"]
                }
            },
            {
                "name": "list_directory",
                "description": "列出目录内容",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "path": {"type": "string", "description": "目录路径"}
                    }
                }
            },
            {
                "name": "get_system_info",
                "description": "获取系统信息",
                "inputSchema": {"type": "object", "properties": {}}
            },
            {
                "name": "install_app",
                "description": "安装应用程序",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "package": {"type": "string", "description": "包名称"}
                    },
                    "required": ["package"]
                }
            }
        ]
    
    def execute_tool(self, tool_name: str, arguments: Dict) -> Any:
        """执行 MCP 工具"""
        handlers = {
            "search_web": self._search_web,
            "run_command": self._run_command,
            "read_file": self._read_file,
            "write_file": self._write_file,
            "list_directory": self._list_directory,
            "get_system_info": self._get_system_info,
            "install_app": self._install_app
        }
        
        handler = handlers.get(tool_name)
        if handler:
            return handler(arguments)
        return {"error": f"未知工具: {tool_name}"}
    
    def _search_web(self, args: Dict) -> Dict:
        """联网搜索"""
        query = args.get("query", "")
        try:
            result = subprocess.run(
                ["curl", "-s", f"https://duckduckgo.com/?q={query}&format=json"],
                capture_output=True, timeout=10
            )
            return {"success": True, "result": result.stdout[:500]}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _run_command(self, args: Dict) -> Dict:
        """执行命令"""
        cmd = args.get("command", "")
        try:
            result = subprocess.run(
                cmd, shell=True, capture_output=True, text=True, timeout=30
            )
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout[:1000],
                "stderr": result.stderr[:500]
            }
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _read_file(self, args: Dict) -> Dict:
        """读取文件"""
        path = args.get("path", "")
        try:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read(5000)
            return {"success": True, "content": content}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _write_file(self, args: Dict) -> Dict:
        """写入文件"""
        path = args.get("path", "")
        content = args.get("content", "")
        try:
            os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
            return {"success": True, "path": path}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _list_directory(self, args: Dict) -> Dict:
        """列出目录"""
        path = args.get("path", ".")
        try:
            items = os.listdir(path)
            return {"success": True, "items": items[:50]}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _get_system_info(self, args: Dict) -> Dict:
        """系统信息"""
        try:
            result = subprocess.run(
                ["neofetch", "--stdout"],
                capture_output=True, text=True, timeout=5
            )
            return {"success": True, "info": result.stdout}
        except:
            return {
                "success": True,
                "info": f"OS: Fishing OS\nKernel: {os.uname().release}\nShell: {os.getenv('SHELL', 'unknown')}"
            }
    
    def _install_app(self, args: Dict) -> Dict:
        """安装应用"""
        package = args.get("package", "")
        try:
            result = subprocess.run(
                ["sudo", "apt", "install", "-y", package],
                capture_output=True, text=True, timeout=120
            )
            return {
                "success": result.returncode == 0,
                "output": result.stdout if result.returncode == 0 else result.stderr
            }
        except Exception as e:
            return {"success": False, "error": str(e)}


def main():
    print("🐟 Fishing OS AI 助手")
    print("=" * 40)
    
    assistant = FishingAssistant()
    
    # 检查服务状态
    print("\n🔍 检查 Ollama 服务...")
    if not assistant.check_ollama():
        print("⚠️  Ollama 服务未运行")
        print("   请运行: ollama serve")
        sys.exit(1)
    
    print("✅ Ollama 服务正常")
    
    # 检查模型
    print("\n📦 检查 AI 模型...")
    result = assistant.chat("你好")
    if "错误" not in result:
        print("✅ AI 模型已就绪")
    else:
        print("⚠️  需要下载模型")
        print("   运行: ollama pull qwen2.5:3b")
    
    print("\n" + "=" * 40)
    print("💡 使用方法:")
    print("   assistant.chat('你的问题')")
    print("   assistant.execute_tool('工具名', {参数})")
    print("   assistant.mcp_tools()  # 查看可用工具")
    print("=" * 40)


if __name__ == "__main__":
    main()
