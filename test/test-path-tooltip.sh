#!/bin/bash

echo "启动文件路径Tooltip功能测试页面..."

# 检查是否有Python3
if command -v python3 &> /dev/null; then
    echo "使用Python3启动HTTP服务器..."
    python3 -m http.server 8080
elif command -v python &> /dev/null; then
    echo "使用Python启动HTTP服务器..."
    python -m SimpleHTTPServer 8080
else
    echo "错误: 未找到Python或Python3，无法启动HTTP服务器"
    echo "请手动在浏览器中打开 test/test-path-tooltip.html 文件"
    exit 1
fi

echo ""
echo "测试页面已启动，请在浏览器中访问:"
echo "http://localhost:8080/test/test-path-tooltip.html"
echo ""
echo "按 Ctrl+C 停止服务器"
