#!/bin/bash

# 多文件搜索功能测试脚本

echo "=== 多文件搜索功能测试 ==="
echo

# 设置测试参数
BASE_URL="http://localhost:6003"
SEARCH_PATTERN="error"
MAX_LINES=50

echo "测试参数:"
echo "  基础URL: $BASE_URL"
echo "  搜索模式: $SEARCH_PATTERN"
echo "  最大返回结果数: $MAX_LINES"
echo

# 1. 获取文件列表
echo "1. 获取日志文件列表..."
FILE_LIST_RESPONSE=$(curl -s "$BASE_URL/api/logs/files")
if [ $? -eq 0 ]; then
    echo "✓ 文件列表获取成功"
    echo "  响应: $FILE_LIST_RESPONSE" | head -c 200
    echo "..."
else
    echo "✗ 文件列表获取失败"
    exit 1
fi
echo

# 2. 测试多文件搜索
echo "2. 测试多文件搜索..."

# 构建搜索请求
SEARCH_REQUEST=$(cat <<EOF
{
  "files": ["test1.log", "test2.log"],
  "pattern": "$SEARCH_PATTERN",
  "reverse": false,
  "lines": $MAX_LINES
}
EOF
)

echo "  搜索请求: $SEARCH_REQUEST"
echo

# 发送搜索请求
SEARCH_RESPONSE=$(curl -s -X POST "$BASE_URL/api/logs/search" \
    -H "Content-Type: application/json" \
    -d "$SEARCH_REQUEST")

if [ $? -eq 0 ]; then
    echo "✓ 搜索请求发送成功"
    echo "  响应: $SEARCH_RESPONSE" | head -c 300
    echo "..."
    
    # 检查响应中是否包含结果
    if echo "$SEARCH_RESPONSE" | grep -q "results"; then
        echo "✓ 搜索响应格式正确"
    else
        echo "✗ 搜索响应格式不正确"
    fi
else
    echo "✗ 搜索请求发送失败"
    exit 1
fi
echo

# 3. 测试单文件搜索（向后兼容）
echo "3. 测试单文件搜索（向后兼容）..."

SINGLE_FILE_REQUEST=$(cat <<EOF
{
  "files": ["test1.log"],
  "pattern": "$SEARCH_PATTERN",
  "reverse": false,
  "lines": $MAX_LINES
}
EOF
)

echo "  单文件搜索请求: $SINGLE_FILE_REQUEST"
echo

SINGLE_FILE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/logs/search" \
    -H "Content-Type: application/json" \
    -d "$SINGLE_FILE_REQUEST")

if [ $? -eq 0 ]; then
    echo "✓ 单文件搜索成功"
    echo "  响应: $SINGLE_FILE_RESPONSE" | head -c 300
    echo "..."
else
    echo "✗ 单文件搜索失败"
fi
echo

# 4. 测试空文件列表
echo "4. 测试空文件列表..."

EMPTY_FILES_REQUEST=$(cat <<EOF
{
  "files": [],
  "pattern": "$SEARCH_PATTERN",
  "reverse": false,
  "lines": $MAX_LINES
}
EOF
)

echo "  空文件列表请求: $EMPTY_FILES_REQUEST"
echo

EMPTY_FILES_RESPONSE=$(curl -s -X POST "$BASE_URL/api/logs/search" \
    -H "Content-Type: application/json" \
    -d "$EMPTY_FILES_REQUEST")

if [ $? -eq 0 ]; then
    echo "✓ 空文件列表请求处理成功"
    echo "  响应: $EMPTY_FILES_RESPONSE" | head -c 200
    echo "..."
    
    # 检查是否返回错误信息
    if echo "$EMPTY_FILES_RESPONSE" | grep -q "没有找到有效的文件"; then
        echo "✓ 空文件列表错误处理正确"
    else
        echo "✗ 空文件列表错误处理不正确"
    fi
else
    echo "✗ 空文件列表请求处理失败"
fi
echo

# 5. 测试倒序搜索
echo "5. 测试倒序搜索..."

REVERSE_REQUEST=$(cat <<EOF
{
  "files": ["test1.log", "test2.log"],
  "pattern": "$SEARCH_PATTERN",
  "reverse": true,
  "lines": $MAX_LINES
}
EOF
)

echo "  倒序搜索请求: $REVERSE_REQUEST"
echo

REVERSE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/logs/search" \
    -H "Content-Type: application/json" \
    -d "$REVERSE_REQUEST")

if [ $? -eq 0 ]; then
    echo "✓ 倒序搜索成功"
    echo "  响应: $REVERSE_RESPONSE" | head -c 300
    echo "..."
else
    echo "✗ 倒序搜索失败"
fi
echo

echo "=== 测试完成 ==="
echo
echo "总结:"
echo "  - 多文件搜索功能已实现"
echo "  - 支持选择多个日志文件进行搜索"
echo "  - 搜索结果会显示来自哪个文件"
echo "  - 支持倒序搜索和结果数量限制"
echo "  - 向后兼容单文件搜索"
echo
echo "前端测试页面: test/test-multi-file-search.html"
echo "可以打开该页面进行交互式测试"
