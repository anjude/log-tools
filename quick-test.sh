#!/bin/bash

echo "🧪 快速测试配置修复..."

# 检查配置文件
echo "📋 检查配置文件..."
if [ -f "config.yaml" ]; then
    echo "✅ config.yaml 存在"
    echo "   端口: $(grep 'port:' config.yaml | head -1 | awk '{print $2}')"
    echo "   用户名: $(grep 'username:' config.yaml | head -1 | awk '{print $2}')"
    echo "   日志目录: $(grep 'directory:' config.yaml | head -1 | awk '{print $2}')"
else
    echo "❌ config.yaml 不存在"
    exit 1
fi

# 检查日志目录
echo ""
echo "📁 检查日志目录..."
if [ -d "logs" ]; then
    echo "✅ logs 目录存在"
    ls -la logs/
else
    echo "❌ logs 目录不存在"
fi

# 检查Go环境
echo ""
echo "🔍 检查Go环境..."
if command -v go &> /dev/null; then
    echo "✅ Go已安装: $(go version)"
else
    echo "❌ Go未安装"
    exit 1
fi

# 安装依赖
echo ""
echo "📦 安装Go依赖..."
go mod tidy

# 测试编译
echo ""
echo "🔨 测试编译..."
if go build -o test-log-tools main.go; then
    echo "✅ 编译成功"
    rm -f test-log-tools
else
    echo "❌ 编译失败"
    exit 1
fi

echo ""
echo "🎉 所有测试通过！"
echo "现在可以运行: ./start.sh"
