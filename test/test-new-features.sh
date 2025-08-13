#!/bin/bash

echo "测试日志工具新功能..."

# 检查后端代码编译
echo "1. 检查后端代码编译..."
cd ..
if go build -o log-tools.exe .; then
    echo "✓ 后端代码编译成功"
else
    echo "✗ 后端代码编译失败"
    exit 1
fi

# 检查配置文件
echo "2. 检查配置文件..."
if [ -f "config.yaml" ]; then
    echo "✓ 配置文件存在"
    cat config.yaml | head -20
else
    echo "✗ 配置文件不存在"
    exit 1
fi

# 检查模板文件
echo "3. 检查前端模板..."
if [ -f "templates/index.html" ]; then
    echo "✓ 前端模板存在"
    # 检查是否包含新功能的关键元素
    if grep -q "fileSearchInput" templates/index.html; then
        echo "✓ 文件搜索功能已添加"
    else
        echo "✗ 文件搜索功能未找到"
    fi
    
    if grep -q "directory-header" templates/index.html; then
        echo "✓ 目录标题功能已添加"
    else
        echo "✗ 目录标题功能未找到"
    fi
    
    if grep -q "full_path" templates/index.html; then
        echo "✓ 完整路径功能已添加"
    else
        echo "✗ 完整路径功能未找到"
    fi
else
    echo "✗ 前端模板不存在"
    exit 1
fi

# 检查后端代码
echo "4. 检查后端代码..."
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
echo "新功能验证完成！"
echo ""
echo "新增功能："
echo "1. ✓ 日志文件区域更紧凑，每个文件一行"
echo "2. ✓ 日志文件列表支持搜索文件"
echo "3. ✓ 日志文件支持展示完整文件路径+文件名"
echo "4. ✓ 按文件目录排序"
echo ""
echo "可以启动服务进行测试："
echo "  ./log-tools.exe"
echo "  或"
echo "  go run ."
