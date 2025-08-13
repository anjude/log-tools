#!/bin/bash

# 日志管理工具 Supervisor 安装脚本
# 适用于 Ubuntu/Debian 和 CentOS/RHEL 系统

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
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    log_info "检测到操作系统: $OS $VER"
}

# 安装supervisor
install_supervisor() {
    log_info "开始安装supervisor..."
    
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        apt-get update
        apt-get install -y supervisor
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        yum install -y supervisor
        systemctl enable supervisord
        systemctl start supervisord
    elif command -v dnf &> /dev/null; then
        # Fedora
        dnf install -y supervisor
        systemctl enable supervisord
        systemctl start supervisord
    else
        log_error "不支持的操作系统，请手动安装supervisor"
        exit 1
    fi
    
    log_info "supervisor安装完成"
}

# 创建应用目录
create_app_directory() {
    log_info "创建应用目录..."
    
    mkdir -p /opt/log-tools
    mkdir -p /var/log/supervisor
    
    log_info "应用目录创建完成"
}

# 复制应用文件
copy_app_files() {
    log_info "复制应用文件..."
    
    # 检查当前目录是否有构建好的二进制文件
    if [[ -f "./build/log-tools" ]]; then
        cp ./build/log-tools /opt/log-tools/
    elif [[ -f "./build/log-tools-linux" ]]; then
        cp ./build/log-tools-linux /opt/log-tools/log-tools
    else
        log_warn "未找到构建好的二进制文件，请先运行 'make build-linux'"
        log_info "继续安装supervisor配置..."
    fi
    
    # 复制配置文件
    if [[ -f "./config.yaml" ]]; then
        cp ./config.yaml /opt/log-tools/
    fi
    
    # 复制模板文件
    if [[ -d "./templates" ]]; then
        cp -r ./templates /opt/log-tools/
    fi
    
    # 设置权限
    chmod +x /opt/log-tools/log-tools 2>/dev/null || true
    chown -R root:root /opt/log-tools
    
    log_info "应用文件复制完成"
}

# 配置supervisor
configure_supervisor() {
    log_info "配置supervisor..."
    
    # 复制supervisor配置文件
    cp ./supervisor.conf /etc/supervisor/conf.d/log-tools.conf
    
    # 重新加载supervisor配置
    supervisorctl reread
    supervisorctl update
    
    log_info "supervisor配置完成"
}

# 启动服务
start_service() {
    log_info "启动log-tools服务..."
    
    supervisorctl start log-tools
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if supervisorctl status log-tools | grep -q "RUNNING"; then
        log_info "log-tools服务启动成功！"
        log_info "服务状态:"
        supervisorctl status log-tools
        log_info "访问地址: http://localhost:6003"
    else
        log_error "log-tools服务启动失败"
        log_info "查看日志: tail -f /var/log/supervisor/log-tools.log"
        exit 1
    fi
}

# 显示使用说明
show_usage() {
    log_info "Supervisor管理命令:"
    echo "  查看状态: supervisorctl status log-tools"
    echo "  启动服务: supervisorctl start log-tools"
    echo "  停止服务: supervisorctl stop log-tools"
    echo "  重启服务: supervisorctl restart log-tools"
    echo "  查看日志: tail -f /var/log/supervisor/log-tools.log"
    echo "  重新加载配置: supervisorctl reread && supervisorctl update"
    echo ""
    log_info "配置文件位置: /etc/supervisor/conf.d/log-tools.conf"
    log_info "应用目录: /opt/log-tools"
}

# 主函数
main() {
    log_info "开始安装log-tools supervisor服务..."
    
    check_root
    detect_os
    install_supervisor
    create_app_directory
    copy_app_files
    configure_supervisor
    start_service
    show_usage
    
    log_info "安装完成！"
}

# 运行主函数
main "$@"
