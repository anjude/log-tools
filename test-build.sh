#!/bin/bash

# 测试构建脚本

echo "🧪 测试项目构建..."

# 检查Go环境
if ! command -v go &> /dev/null; then
    echo "❌ Go未安装，跳过构建测试"
    exit 0
fi

# 清理之前的构建
echo "🧹 清理之前的构建..."
rm -f log-tools
rm -rf build/

# 安装依赖
echo "📦 安装依赖..."
go mod tidy

# 检查依赖
echo "🔍 检查依赖..."
go mod verify

# 代码检查
echo "🔍 代码检查..."
go vet ./...
gofmt -l . | head -10

# 构建项目
echo "🔨 构建项目..."
go build -o log-tools main.go

if [[ -f log-tools ]]; then
    echo "✅ 构建成功！"
    echo "📁 生成文件: $(ls -lh log-tools)"
    
    # 测试运行（短暂运行）
    echo "🚀 测试运行（5秒）..."
    timeout 5s ./log-tools &
    PID=$!
    sleep 2
    
    # 检查服务是否启动
    if curl -s http://localhost:6003/api/check-auth > /dev/null 2>&1; then
        echo "✅ 服务启动成功！"
    else
        echo "⚠️  服务启动检查失败"
    fi
    
    # 停止服务
    kill $PID 2>/dev/null || true
    wait $PID 2>/dev/null || true
    
    echo "✅ 构建测试完成！"
else
    echo "❌ 构建失败！"
    exit 1
fi
