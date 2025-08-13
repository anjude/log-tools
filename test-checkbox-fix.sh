#!/bin/bash

echo "测试复选框位置修复..."
echo "================================"

# 检查主模板文件中的关键修改
echo "1. 检查HTML结构修改..."
if grep -q "file-item-layout" templates/index.html; then
    echo "✓ file-item-layout 类已添加"
else
    echo "✗ file-item-layout 类未找到"
fi

if grep -q "checkbox-container" templates/index.html; then
    echo "✓ checkbox-container 类已添加"
else
    echo "✗ checkbox-container 类未找到"
fi

echo ""
echo "2. 检查CSS样式修改..."
if grep -q "\.checkbox-container" templates/index.html; then
    echo "✓ checkbox-container CSS样式已添加"
else
    echo "✗ checkbox-container CSS样式未找到"
fi

if grep -q "\.file-item-layout" templates/index.html; then
    echo "✓ file-item-layout CSS样式已添加"
else
    echo "✗ file-item-layout CSS样式未找到"
fi

echo ""
echo "3. 检查复选框HTML结构..."
if grep -q '<div class="checkbox-container">' templates/index.html; then
    echo "✓ 复选框容器HTML结构已更新"
else
    echo "✗ 复选框容器HTML结构未更新"
fi

echo ""
echo "4. 创建测试页面..."
if [ -f "test-checkbox-position.html" ]; then
    echo "✓ 测试页面已创建"
    echo "   可以在浏览器中打开 test-checkbox-position.html 来验证复选框位置"
else
    echo "✗ 测试页面创建失败"
fi

echo ""
echo "测试完成！"
echo "================================"
echo "如果所有检查都通过，复选框应该已经固定在文件项的最左侧。"
echo "可以在浏览器中打开测试页面来验证效果。"
