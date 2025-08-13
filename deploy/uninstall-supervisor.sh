#!/bin/bash

# 日志管理工具 Supervisor 卸载脚本

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

# 停止服务
stop_service() {
    log_info "停止log-tools服务..."
    
    if supervisorctl status log-tools &>/dev/null; then
        supervisorctl stop log-tools
        log_info "服务已停止"
    else
        log_warn "服务未运行或未找到"
    fi
}

# 移除supervisor配置
remove_supervisor_config() {
    log_info "移除supervisor配置..."
    
    if [[ -f "/etc/supervisor/conf.d/log-tools.conf" ]]; then
        rm -f /etc/supervisor/conf.d/log-tools.conf
        supervisorctl reread
        supervisorctl update
        log_info "supervisor配置已移除"
    else
        log_warn "supervisor配置文件不存在"
    fi
}

# 移除应用文件
remove_app_files() {
    log_info "移除应用文件..."
    
    if [[ -d "/opt/log-tools" ]]; then
        rm -rf /opt/log-tools
        log_info "应用文件已移除"
    else
        log_warn "应用目录不存在"
    fi
}

# 清理日志文件
cleanup_logs() {
    log_info "清理日志文件..."
    
    if [[ -f "/var/log/supervisor/log-tools.log" ]]; then
        rm -f /var/log/supervisor/log-tools.log
        rm -f /var/log/supervisor/log-tools-error.log
        log_info "日志文件已清理"
    fi
}

# 显示卸载完成信息
show_completion() {
    log_info "卸载完成！"
    log_info "注意：supervisor本身并未卸载，如需完全卸载请运行:"
    echo "  Ubuntu/Debian: apt-get remove --purge supervisor"
    echo "  CentOS/RHEL: yum remove supervisor"
}

# 主函数
main() {
    log_info "开始卸载log-tools supervisor服务..."
    
    check_root
    stop_service
    remove_supervisor_config
    remove_app_files
    cleanup_logs
    show_completion
    
    log_info "卸载完成！"
}

# 运行主函数
main "$@"
