#!/bin/bash

echo "测试拖拽调节宽度功能"
echo "===================="

# 检查是否在正确的目录
if [ ! -f "test-resize.html" ]; then
    echo "错误：请在test目录下运行此脚本"
    exit 1
fi

# 启动Python HTTP服务器
echo "启动测试服务器..."
echo "请在浏览器中访问: http://localhost:8000/test-resize.html"
echo "按 Ctrl+C 停止服务器"
echo ""

python3 -m http.server 8000 2>/dev/null || python -m http.server 8000 2>/dev/null || echo "请安装Python来启动测试服务器"
