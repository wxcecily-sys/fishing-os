#!/bin/bash
#===========================================
# Fishing OS 构建脚本 v1.0
# 基于 Ubuntu 22.04 LTS
#===========================================

set -e  # 遇错即停

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
WORK_DIR="$HOME/fishing-os-build"
ISO_OUTPUT="$HOME/fishing-os-iso"
PROJECT_DIR="$HOME/.qclaw/workspace/fishing-os"

# 下载的 Ubuntu 镜像 (22.04 LTS)
UBUNTU_ISO="ubuntu-22.04.5-desktop-amd64.iso"
UBUNTU_URL="https://releases.ubuntu.com/22.04/${UBUNTU_ISO}"

echo_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

echo -e "${GREEN}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║       🐟 Fishing OS 构建工具 🐟       ║"
echo "  ║         Version 1.0                  ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"

# 检查是否 root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}⚠️  请勿使用 root 运行此脚本！${NC}"
    exit 1
fi

#===========================================
# 步骤 1: 安装必要工具
#===========================================
echo_step "步骤 1/6: 安装必要工具"

sudo apt update
sudo apt install -y \
    cubic \
    wget \
    bsdtar \
    xorriso \
    squashfs-tools \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    fuse \
    libfuse2 \
    fuseiso \
    7zip \
    p7zip-full

echo -e "${GREEN}✓ 工具安装完成${NC}"

#===========================================
# 步骤 2: 下载 Ubuntu 基础镜像
#===========================================
echo_step "步骤 2/6: 下载 Ubuntu 22.04 基础镜像"

mkdir -p "$ISO_OUTPUT"
cd "$ISO_OUTPUT"

if [ -f "$UBUNTU_ISO" ]; then
    echo -e "${YELLOW}检测到已有镜像，跳过下载${NC}"
else
    echo "正在下载 Ubuntu 22.04 Desktop AMD64..."
    wget -c --progress=bar:force "$UBUNTU_URL"
fi

echo -e "${GREEN}✓ 镜像下载完成${NC}"

#===========================================
# 步骤 3: 解压并修改系统
#===========================================
echo_step "步骤 3/6: 解压并修改系统"

CUSTOMIZE_DIR="$ISO_OUTPUT/fishing-os-custom"

# 复制镜像到工作目录
mkdir -p "$WORK_DIR"
sudo rm -rf "$CUSTOMIZE_DIR"
mkdir -p "$CUSTOMIZE_DIR"

# 解压 ISO
echo "正在解压 ISO..."
7z x "$UBUNTU_ISO" -o"$WORK_DIR/iso-extract" -y > /dev/null

# 挂载 squashfs
sudo mount --bind "$WORK_DIR/iso-extract" "$CUSTOMIZE_DIR"
sudo modprobe squashfs
sudo mount -t squashfs "$WORK_DIR/iso-extract/casper/filesystem.squashfs" "$CUSTOMIZE_DIR" -o loop

echo -e "${GREEN}✓ 系统解压完成${NC}"

#===========================================
# 步骤 4: 安装软件包
#===========================================
echo_step "步骤 4/6: 安装 Fishing OS 组件"

# 配置 chroot 环境
sudo mount -t proc proc "$CUSTOMIZE_DIR/proc"
sudo mount -t sysfs sys "$CUSTOMIZE_DIR/sys"
sudo mount --bind /dev "$CUSTOMIZE_DIR/dev"
sudo mount --bind /dev/pts "$CUSTOMIZE_DIR/dev/pts"

# 添加 PPA 和安装包
cat << 'CHROOT_EOF' | sudo chroot "$CUSTOMIZE_DIR" /bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

echo "==> 更新软件源..."
apt update

echo "==> 安装 Wine + Bottles..."
dpkg --add-architecture i386
wget -qO- https://dl.winehq.org/wine-builds/winehq.key | apt-key add -
apt-add-repository 'https://dl.winehq.org/wine-builds/ubuntu/'
apt update
apt install -y --install-recommends winehq-stable wine-stable-i386 wine-stable

echo "==> 安装 Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

echo "==> 安装开发工具..."
apt install -y \
    git \
    curl \
    wget \
    python3 \
    python3-pip \
    code \
    build-essential

echo "==> 安装游戏工具..."
apt install -y gamemode

echo "==> 安装多媒体解码器..."
apt install -y \
    vlc \
    vlc-l10n \
    libavcodec-extra

echo "==> 安装网络工具..."
apt install -y \
    network-manager \
    network-manager-gnome

echo "==> 清理缓存..."
apt clean
apt autoremove -y

echo "==> 安装 MCP Server..."
pip3 install mcp-server-filesystem mcp-server-shell

echo "✅ 软件安装完成"
CHROOT_EOF

# 卸载挂载
sudo umount "$CUSTOMIZE_DIR/dev/pts" 2>/dev/null || true
sudo umount "$CUSTOMIZE_DIR/dev" 2>/dev/null || true
sudo umount "$CUSTOMIZE_DIR/sys" 2>/dev/null || true
sudo umount "$CUSTOMIZE_DIR/proc" 2>/dev/null || true
sudo umount "$CUSTOMIZE_DIR" 2>/dev/null || true

echo -e "${GREEN}✓ 软件安装完成${NC}"

#===========================================
# 步骤 5: 配置系统
#===========================================
echo_step "步骤 5/6: 配置 Fishing OS"

# 创建配置文件
mkdir -p "$PROJECT_DIR/config"

# 创建 Ollama 服务配置
cat > "$PROJECT_DIR/config/ollama.service" << 'EOF'
[Unit]
Description=Ollama Local AI Server
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/ollama serve
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 创建 MCP Server 启动脚本
cat > "$PROJECT_DIR/config/start-mcp.sh" << 'EOF'
#!/bin/bash
# Fishing OS MCP AI 助手启动脚本

echo "🤖 正在启动 Fishing AI 助手..."
echo

# 启动 Ollama (后台)
if ! pgrep -x "ollama" > /dev/null; then
    echo "启动 Ollama 服务..."
    ollama serve &
    sleep 3
fi

# 下载默认模型 (首次运行)
if ! ollama list | grep -q "qwen2.5"; then
    echo "首次使用，正在下载 AI 模型..."
    echo "(可随时中断，模型会在后台继续下载)"
    ollama pull qwen2.5:3b
fi

echo
echo "✅ Fishing AI 助手就绪！"
echo "   运行 'ollama run qwen2.5:3b' 开始对话"
EOF

chmod +x "$PROJECT_DIR/config/start-mcp.sh"

# 创建 Wine 预配置
cat > "$PROJECT_DIR/config/wine-init.sh" << 'EOF'
#!/bin/bash
# Fishing OS Wine 初始化脚本

echo "🍷 初始化 Wine 环境..."

# 创建默认前缀
WINEPREFIX="$HOME/.wine" WINEARCH=win64 wineboot --init

# 安装常用组件
WINEPREFIX="$HOME/.wine" winetricks -q \
    vcrun2022 \
    dotnet48 \
    dxvk

echo "✅ Wine 环境就绪！"
EOF

chmod +x "$PROJECT_DIR/config/wine-init.sh"

# 创建桌面快捷方式
mkdir -p "$PROJECT_DIR/desktop"

cat > "$PROJECT_DIR/desktop/fishing-ai.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Fishing AI 助手
Name[zh_CN]=Fishing AI 助手
Comment=本地 AI 助手 (基于 Ollama)
Icon=utilities-terminal
Exec=gnome-terminal -- /home/fishing/.qclaw/workspace/fishing-os/config/start-mcp.sh
Terminal=true
Categories=System;Utility;
EOF

cat > "$PROJECT_DIR/desktop/wine-init.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=初始化 Wine 环境
Name[zh_CN]=初始化 Wine 环境
Comment=为 Fishing OS 配置 Wine 兼容层
Icon=wine
Exec=/home/fishing/.qclaw/workspace/fishing-os/config/wine-init.sh
Terminal=true
Categories=System;Utility;
EOF

echo -e "${GREEN}✓ 系统配置完成${NC}"

#===========================================
# 步骤 6: 构建 ISO
#===========================================
echo_step "步骤 6/6: 构建 Fishing OS ISO"

# 使用 Cubic 生成 ISO
cubic "$ISO_OUTPUT" --quiet

echo -e "${GREEN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Fishing OS 构建完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "📦 ISO 文件位置: $ISO_OUTPUT"
echo
echo "⚠️  注意:"
echo "   1. 首次启动时会下载 AI 模型 (~2GB)"
echo "   2. 运行 wine-init.desktop 初始化 Wine"
echo "   3. 游戏用户请安装 Steam"
echo
echo "🐟 祝您使用愉快！"
echo -e "${NC}"

echo -e "${YELLOW}还需要我做什么？比如：${NC}"
echo "   1. 创建详细的图文安装教程"
echo "   2. 制作系统美化包"
echo "   3. 配置自动化测试脚本"
