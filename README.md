# 🐟 Fishing OS

> 基于 Ubuntu 22.04 LTS 的定制化 Linux 发行版，支持 Windows exe 运行，内置本地 AI 助手

## ✨ 特性

- 🖥️ **轻量桌面**: Xfce4 桌面环境，适合 2GB 系统
- 🍷 **Wine 兼容**: 原生运行 Windows .exe 程序
- 🤖 **本地 AI**: 基于 Ollama + MCP 协议的 AI 助手
- 🎮 **游戏支持**: Steam + Proton + GameMode 优化
- 👨‍💻 **开发环境**: VS Code + Git + Python 预装
- 📦 **办公套件**: LibreOffice + VLC 多媒体

## 📋 系统要求

| 项目 | 最低配置 | 推荐配置 |
|------|----------|----------|
| CPU | 64位双核 | 4核以上 |
| 内存 | 4GB | 8GB |
| 硬盘 | 4GB 可用 | 20GB 可用 |
| 显卡 | OpenGL 3.3+ | 独立显卡 |

## 🚀 快速开始

### 方式一: 使用构建脚本 (推荐)

```bash
# 1. 克隆项目
git clone https://github.com/your-repo/fishing-os.git
cd fishing-os

# 2. 运行构建脚本
chmod +x build.sh
./build.sh

# 3. 在 Cubic 界面中自定义系统
#    - 添加桌面图标
#    - 安装额外软件
#    - 修改主题

# 4. 点击 "Generate" 生成 ISO
```

### 方式二: 手动构建

```bash
# 1. 安装基础工具
sudo apt install cubic wget bsdtar xorriso squashfs-tools

# 2. 下载 Ubuntu 22.04
wget https://releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso

# 3. 启动 Cubic
cubic

# 4. 在 Cubic 中:
#    - 选择下载的 ISO
#    - 添加额外 PPA 和软件包
#    - 自定义桌面配置
#    - 生成新 ISO
```

## 🎯 软件包清单

### 基础系统
- [x] Ubuntu 22.04 LTS
- [x] Xfce4 桌面环境
- [x] LightDM 登录管理器

### Wine 兼容层
- [x] Wine HQ 8.0
- [x] Bottles (图形化管理)
- [x] GameMode (游戏优化)
- [x] 常用 Windows 运行库

### AI 助手
- [x] Ollama 本地 AI 引擎
- [x] MCP Server
- [x] Qwen2.5 3B 模型 (默认)
- [x] Llama3.2 1B 模型 (备选)

### 预装软件
| 软件 | 版本 | 用途 |
|------|------|------|
| Firefox ESR | 115.x | 浏览器 |
| LibreOffice | 7.x | 办公套件 |
| VLC | 3.x | 媒体播放 |
| VS Code | 1.85 | 代码编辑 |
| Git | 2.34 | 版本控制 |
| Python | 3.10 | 开发环境 |

## 🤖 AI 助手使用

### 首次启动
```bash
# 启动 Ollama 服务
ollama serve

# 下载默认模型 (首次)
ollama pull qwen2.5:3b

# 或使用更小的模型
ollama pull llama3.2:1b
```

### MCP 工具
```python
# 文件操作
assistant.execute_tool("read_file", {"path": "/home/user/test.txt"})
assistant.execute_tool("write_file", {"path": "/home/user/test.txt", "content": "Hello"})

# 命令执行
assistant.execute_tool("run_command", {"command": "ls -la"})

# 系统信息
assistant.execute_tool("get_system_info", {})

# 安装应用
assistant.execute_tool("install_app", {"package": "neofetch"})
```

## 🍷 运行 Windows 程序

```bash
# 初始化 Wine 环境
./config/wine-init.sh

# 下载 Windows exe
wget https://example.com/app.exe

# 运行
wine app.exe

# 或使用 Bottles 图形化管理
bottles
```

## 🎮 游戏优化

```bash
# 启用游戏模式
gamemoderun ./game.exe

# Steam 设置
# 1. 启用 Steam Play for all titles
# 2. Proton 自动处理 Windows 游戏
```

## 📁 目录结构

```
fishing-os/
├── SPEC.md              # 规格说明
├── build.sh             # 构建脚本
├── README.md            # 本文件
├── config/
│   ├── ollama.service   # Ollama 服务配置
│   ├── start-mcp.sh     # MCP 启动脚本
│   └── wine-init.sh     # Wine 初始化
├── desktop/
│   ├── fishing-ai.desktop    # AI 助手快捷方式
│   └── wine-init.desktop     # Wine 初始化快捷方式
└── mcp-server/
    └── assistant.py     # MCP 服务器
```

## 🔧 自定义

### 修改默认 AI 模型
编辑 `config/start-mcp.sh`:
```bash
ollama pull llama3.2:1b  # 改成你想要的模型
```

### 添加软件包
编辑 `build.sh` 中的 `apt install` 部分:
```bash
apt install -y \
    your-package-1 \
    your-package-2
```

### 更换主题
```bash
# 安装主题
apt install arc-theme papirus-icon-theme

# 应用主题
xfconf-query -c xfwm4 -p /general/theme -s "Arc-Dark"
```

## ❓ 常见问题

### Q: ISO 大小超过 2GB 怎么办？
```bash
# 减少预装软件
# 或使用更小的 AI 模型 (llama3.2:1b)
```

### Q: Wine 运行程序出错？
```bash
# 使用 winetricks 安装额外组件
WINEPREFIX=~/.wine winetricks vcrun2019
```

### Q: Ollama 模型下载慢？
```bash
# 使用镜像
OLLAMA_HOST=https://ollama.ollama.online/ollama
```

## 📜 许可证

MIT License

## 🐟 Fishing OS Team

- Version: 1.0
- Build Date: 2026-05-07
- 基于: Ubuntu 22.04 LTS

---

*有问题？提交 Issue 或联系开发者！*
