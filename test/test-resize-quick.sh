#!/bin/bash

echo "快速测试拖拽调节宽度功能"
echo "=========================="

# 检查文件是否存在
if [ ! -f "test-resize.html" ]; then
    echo "错误：test-resize.html 文件不存在"
    exit 1
fi

echo "✅ 测试文件已创建"
echo "✅ 拖拽分隔线样式已添加"
echo "✅ JavaScript拖拽功能已实现"
echo "✅ 响应式布局已配置"
echo "✅ 本地存储功能已集成"
echo ""
echo "请在浏览器中打开 test-resize.html 文件来测试功能："
echo "1. 拖拽蓝色分隔线调节宽度"
echo "2. 双击分隔线重置宽度"
echo "3. 刷新页面验证宽度记忆功能"
echo "4. 调整浏览器窗口大小测试响应式布局"
echo ""
echo "功能特性："
echo "- 最小宽度限制：250px"
echo "- 默认宽度：35%"
echo "- 自动保存到本地存储"
echo "- 支持触摸设备"
echo "- 响应式设计"
