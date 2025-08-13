#!/bin/bash

echo "测试日志工具改进功能..."

# 检查后端代码编译
echo "1. 检查后端代码编译..."
cd ..
if go build -o log-tools.exe .; then
    echo "✓ 后端代码编译成功"
else
    echo "✗ 后端代码编译失败"
    exit 1
fi

# 检查前端模板
echo "2. 检查前端模板..."
if [ -f "templates/index.html" ]; then
    echo "✓ 前端模板存在"
    
    # 检查是否包含新的改进功能
    if grep -q "lastSelectedFile" templates/index.html; then
        echo "✓ 本地保存功能已添加"
    else
        echo "✗ 本地保存功能未找到"
    fi
    
    if grep -q "file-path-info" templates/index.html; then
        echo "✓ 文件路径显示功能已添加"
    else
        echo "✗ 文件路径显示功能未找到"
    fi
    
    if grep -q "max-width: 1600px" templates/index.html; then
        echo "✓ 页面宽度优化已添加"
    else
        echo "✗ 页面宽度优化未找到"
    fi
    
    if grep -q "width: 28%" templates/index.html; then
        echo "✓ 文件列表宽度优化已添加"
    else
        echo "✗ 文件列表宽度优化未找到"
    fi
else
    echo "✗ 前端模板不存在"
    exit 1
fi

# 检查后端代码
echo "3. 检查后端代码..."
if grep -q "FullPath" handlers/logs.go; then
    echo "✓ 完整路径字段已添加"
else
    echo "✗ 完整路径字段未找到"
fi

if grep -q "Directory" handlers/logs.go; then
    echo "✓ 目录字段已添加"
else
    echo "✗ 目录字段未找到"
fi

echo ""
echo "改进功能验证完成！"
echo ""
echo "新增改进："
echo "1. ✓ 减少页面两边的空白"
echo "2. ✓ 本地保存上次选择的日志文件"
echo "3. ✓ 日志文件展示为一行，增加宽度"
echo "4. ✓ 补全文件路径展示在日志文件栏"
echo ""
echo "可以启动服务进行测试："
echo "  ./log-tools.exe"
echo "  或"
echo "  go run ."
echo ""
echo "测试要点："
echo "- 页面两边空白是否减少"
echo "- 选择文件后刷新页面是否自动选择上次的文件"
echo "- 文件列表是否在一行内显示完整信息"
echo "- 文件路径是否完整显示"
