#!/bin/bash
#===========================================
# Fishing OS - WSL/Ubuntu 命令行构建脚本
# 无需图形界面，纯终端操作
#===========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║    🐟 Fishing OS WSL 构建工具 🐟    ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"

# 检测是否 WSL
if grep -qi microsoft /proc/version; then
    echo -e "${BLUE}检测到 WSL 环境${NC}"
    WSL_MODE=1
else
    echo -e "${BLUE}检测到原生 Linux${NC}"
    WSL_MODE=0
fi

# 安装依赖
echo -e "\n${BLUE}[1/5] 安装构建工具...${NC}"

sudo apt update
sudo apt install -y \
    wget \
    xorriso \
    squashfs-tools \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    7zip \
    debootstrap \
    ubuntu-keyring \
    genisoimage

echo -e "${GREEN}✓ 工具安装完成${NC}"

# 创建工作目录
WORK_DIR="$HOME/fishing-os-workspace"
ISO_DIR="$WORK_DIR/output"
mkdir -p "$ISO_DIR"

echo -e "\n${BLUE}[2/5] 下载 Ubuntu 22.04 基础系统...${NC}"

cd "$WORK_DIR"

if [ -f "ubuntu-22.04-base.tar.gz" ]; then
    echo "使用已有的基础系统..."
else
    echo "下载 Ubuntu 22.04 Server 基础包..."
    debootstrap --arch=amd64 --variant=minbase jammy ubuntu-base http://archive.ubuntu.com/ubuntu/
    
    echo "打包基础系统..."
    tar czf ubuntu-22.04-base.tar.gz -C ubuntu-base .
    rm -rf ubuntu-base
fi

echo -e "${GREEN}✓ 基础系统准备完成${NC}"

# 解压并配置
echo -e "\n${BLUE}[3/5] 配置 Fishing OS 系统...${NC}"

SYSTEM_DIR="$WORK_DIR/fishing-system"
rm -rf "$SYSTEM_DIR"
mkdir -p "$SYSTEM_DIR"

echo "解压基础系统..."
tar xzf ubuntu-22.04-base.tar.gz -C "$SYSTEM_DIR"

# 挂载并配置
sudo mount --bind /dev "$SYSTEM_DIR/dev"
sudo mount -t proc proc "$SYSTEM_DIR/proc"
sudo mount -t sysfs sys "$SYSTEM_DIR/sys"

# 复制源列表
sudo cp /etc/apt/sources.list "$SYSTEM_DIR/etc/apt/sources.list"
sudo cp /etc/resolv.conf "$SYSTEM_DIR/etc/resolv.conf"

# 安装软件
cat << 'CHROOT' | sudo chroot "$SYSTEM_DIR" /bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "更新软件源..."
apt update

echo "安装桌面环境 Xfce4..."
apt install -y xfce4 xfce4-goodies lightdm

echo "安装 Wine..."
dpkg --add-architecture i386
apt update
apt install -y wine wine64 wine32:i386

echo "安装 AI 助手 Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

echo "安装开发工具..."
apt install -y git curl wget python3 python3-pip
pip3 install mcp-server-filesystem

echo "安装浏览器..."
apt install -y firefox

echo "安装办公套件..."
apt install -y libreoffice

echo "安装多媒体播放器..."
apt install -y vlc

echo "安装游戏工具..."
apt install -y gamemode

echo "安装系统工具..."
apt install -y neofetch htop file

echo "清理缓存..."
apt clean
rm -rf /var/lib/apt/lists/*

echo "✅ 系统配置完成"
CHROOT

# 卸载
sudo umount "$SYSTEM_DIR/proc"
sudo umount "$SYSTEM_DIR/sys"
sudo umount "$SYSTEM_DIR/dev"

echo -e "${GREEN}✓ 系统配置完成${NC}"

# 添加 Fishing OS 特有文件
echo -e "\n${BLUE}[4/5] 添加 Fishing OS 定制内容...${NC}"

# AI 助手脚本
sudo mkdir -p "$SYSTEM_DIR/opt/fishing-os"
sudo cp -r "$HOME/.qclaw/workspace/fishing-os/mcp-server" "$SYSTEM_DIR/opt/fishing-os/"

# 启动脚本
cat << 'EOF' | sudo tee "$SYSTEM_DIR/opt/fishing-os/start-ai.sh" > /dev/null
#!/bin/bash
echo "🤖 Fishing OS AI 助手"
echo "===================="
echo
echo "启动 Ollama..."
ollama serve &
sleep 3
echo
echo "首次使用需要下载模型："
echo "  ollama pull qwen2.5:3b"
echo
echo "运行对话："
echo "  ollama run qwen2.5:3b"
EOF
sudo chmod +x "$SYSTEM_DIR/opt/fishing-os/start-ai.sh"

# 桌面快捷方式
sudo mkdir -p "$SYSTEM_DIR/etc/skel/Desktop"
cat << 'EOF' | sudo tee "$SYSTEM_DIR/etc/skel/Desktop/fishing-ai.desktop" > /dev/null
[Desktop Entry]
Name=Fishing AI 助手
Comment=本地 AI 助手
Icon=utilities-terminal
Exec=/opt/fishing-os/start-ai.sh
Terminal=true
Type=Application
Categories=System;Utility;
EOF

# 首次运行配置脚本
cat << 'EOF' | sudo tee "$SYSTEM_DIR/opt/fishing-os/setup-first.sh" > /dev/null
#!/bin/bash
echo "🐟 Fishing OS 首次设置向导"
echo "==========================="
echo
echo "1. 初始化 Wine..."
wineboot --init 2>/dev/null || true

echo "2. 下载 AI 模型..."
read -p "是否现在下载 AI 模型？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ollama pull qwen2.5:3b
fi

echo "3. 清理桌面测试文件..."
rm -f ~/Desktop/*.desktop 2>/dev/null || true

echo
echo "✅ 设置完成！重启后生效"
EOF
sudo chmod +x "$SYSTEM_DIR/opt/fishing-os/setup-first.sh"

echo -e "${GREEN}✓ 定制内容添加完成${NC}"

# 打包 rootfs
echo -e "\n${BLUE}[5/5] 打包 rootfs...${NC}"

ROOTFS="$ISO_DIR/fishing-os-rootfs.tar.gz"
sudo tar czf "$ROOTFS" -C "$SYSTEM_DIR" .
sudo chmod 644 "$ROOTFS"

echo -e "${GREEN}✓ rootfs 打包完成: $ROOTFS${NC}"

# 生成 ISO
echo -e "\n${BLUE}生成 ISO 镜像...${NC}"

ISO_OUTPUT="$ISO_DIR/fishing-os-1.0-amd64.tar.gz"

# 打包整个工作目录
tar czf "$ISO_OUTPUT" -C "$WORK_DIR" .

echo -e "${GREEN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 构建完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "📦 输出文件:"
echo "   - rootfs: $ROOTFS"
echo "   - 完整包: $ISO_OUTPUT"
echo
echo "📦 文件大小:"
ls -lh "$ROOTFS" "$ISO_OUTPUT"
echo
echo "💡 下一步:"
echo "   1. 解压 rootfs 到虚拟机或实体机"
echo "   2. 或者用 Docker 构建 ISO"
echo
echo "🐟 祝您使用愉快！"
echo -e "${NC}"
