#!/bin/bash

# 日志管理工具安装脚本
# 适用于 Ubuntu/Debian/CentOS/RHEL 系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "请不要使用root用户运行此脚本"
        exit 1
    fi
}

# 检查系统类型
check_system() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        log_error "无法检测操作系统类型"
        exit 1
    fi
    
    log_info "检测到操作系统: $OS $VER"
}

# 安装依赖
install_dependencies() {
    log_info "安装系统依赖..."
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        sudo apt-get update
        sudo apt-get install -y curl wget git build-essential
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        sudo yum update -y
        sudo yum install -y curl wget git gcc make
    else
        log_warn "未知的操作系统，请手动安装依赖"
    fi
}

# 安装Go
install_go() {
    if command -v go &> /dev/null; then
        log_info "Go已安装: $(go version)"
        return
    fi
    
    log_info "安装Go语言环境..."
    
    # 下载Go
    GO_VERSION="1.21.5"
    GO_ARCH="linux-amd64"
    GO_URL="https://go.dev/dl/go${GO_VERSION}.${GO_ARCH}.tar.gz"
    
    cd /tmp
    wget -q $GO_URL
    sudo tar -C /usr/local -xzf go${GO_VERSION}.${GO_ARCH}.tar.gz
    
    # 设置环境变量
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
    
    log_info "Go安装完成"
}

# 创建用户和目录
setup_environment() {
    log_info "设置运行环境..."
    
    # 创建用户和组
    if ! id "log-tools" &>/dev/null; then
        sudo useradd -r -s /bin/false -d /opt/log-tools log-tools
        log_info "创建用户 log-tools"
    fi
    
    # 创建应用目录
    sudo mkdir -p /opt/log-tools
    sudo chown log-tools:log-tools /opt/log-tools
    
    # 创建日志目录
    sudo mkdir -p /var/log/log-tools
    sudo chown log-tools:log-tools /var/log/log-tools
}

# 编译项目
build_project() {
    log_info "编译项目..."
    
    # 安装Go依赖
    go mod tidy
    
    # 编译
    go build -o log-tools main.go
    
    if [[ ! -f log-tools ]]; then
        log_error "编译失败"
        exit 1
    fi
    
    log_info "编译完成"
}

# 安装应用
install_application() {
    log_info "安装应用..."
    
    # 复制文件
    sudo cp log-tools /opt/log-tools/
    sudo cp config.yaml /opt/log-tools/
    sudo cp -r templates /opt/log-tools/
    
    # 设置权限
    sudo chown -R log-tools:log-tools /opt/log-tools
    sudo chmod +x /opt/log-tools/log-tools
    
    log_info "应用安装完成"
}

# 安装systemd服务
install_service() {
    log_info "安装systemd服务..."
    
    # 复制服务文件
    sudo cp log-tools.service /etc/systemd/system/
    
    # 重新加载systemd
    sudo systemctl daemon-reload
    
    # 启用服务
    sudo systemctl enable log-tools
    
    log_info "服务安装完成"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow 6003/tcp
        log_info "UFW防火墙规则已添加"
    elif command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-port=6003/tcp
        sudo firewall-cmd --reload
        log_info "firewalld防火墙规则已添加"
    else
        log_warn "未检测到防火墙，请手动配置端口6003"
    fi
}

# 显示安装信息
show_installation_info() {
    log_info "安装完成！"
    echo
    echo "=========================================="
    echo "日志管理工具安装完成"
    echo "=========================================="
    echo "服务状态: sudo systemctl status log-tools"
    echo "启动服务: sudo systemctl start log-tools"
    echo "停止服务: sudo systemctl stop log-tools"
    echo "重启服务: sudo systemctl restart log-tools"
    echo "查看日志: sudo journalctl -u log-tools -f"
    echo "访问地址: http://$(hostname -I | awk '{print $1}'):6003"
    echo "默认用户: milk"
echo "默认密码: milk@123"
    echo "=========================================="
    echo
    log_warn "请立即修改默认密码！"
}

# 主函数
main() {
    log_info "开始安装日志管理工具..."
    
    check_root
    check_system
    install_dependencies
    install_go
    setup_environment
    build_project
    install_application
    install_service
    configure_firewall
    show_installation_info
}

# 运行主函数
main "$@"
