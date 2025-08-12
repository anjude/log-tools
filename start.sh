#!/bin/bash

# 快速启动脚本（开发模式）

echo "🚀 启动日志管理工具..."

# 检查Go是否安装
if ! command -v go &> /dev/null; then
    echo "❌ 错误: 未安装Go语言环境"
    echo "请先安装Go 1.21或更高版本"
    exit 1
fi

# 检查Go版本
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
REQUIRED_VERSION="1.21"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ 错误: Go版本过低，需要1.21或更高版本"
    echo "当前版本: $GO_VERSION"
    exit 1
fi

echo "✅ Go版本检查通过: $GO_VERSION"

# 安装依赖
echo "📦 安装Go依赖..."
go mod tidy

# 检查配置文件
if [ ! -f "config.yaml" ]; then
    echo "❌ 错误: 配置文件config.yaml不存在"
    exit 1
fi

echo "✅ 配置文件检查通过"

# 启动应用
echo "🌐 启动Web服务器..."
echo "访问地址: http://localhost:6003"
echo "默认用户: milk"
echo "默认密码: milk@123"
echo ""
echo "按 Ctrl+C 停止服务"
echo ""

go run main.go
