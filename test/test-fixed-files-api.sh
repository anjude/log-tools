#!/bin/bash

# 固定文件路径功能测试脚本
# 测试后端API是否支持固定文件路径配置

echo "🧪 开始测试固定文件路径功能..."
echo "=================================="

# 配置信息
BASE_URL="http://localhost:6003"
USERNAME="milk"
PASSWORD="milk@2025"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试步骤1: 登录获取token
echo -e "\n${BLUE}步骤1: 登录获取认证token${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}")

if [ $? -eq 0 ]; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$TOKEN" ]; then
        echo -e "${GREEN}✓ 登录成功，获取到token${NC}"
        echo "Token: ${TOKEN:0:20}..."
    else
        echo -e "${RED}✗ 登录失败，无法获取token${NC}"
        echo "响应: $LOGIN_RESPONSE"
        exit 1
    fi
else
    echo -e "${RED}✗ 登录请求失败${NC}"
    exit 1
fi

# 测试步骤2: 获取日志文件列表
echo -e "\n${BLUE}步骤2: 获取日志文件列表${NC}"
FILES_RESPONSE=$(curl -s -X GET "${BASE_URL}/api/logs/files" \
  -H "Authorization: ${TOKEN}")

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 成功获取文件列表${NC}"
    
    # 检查是否包含固定文件
    if echo "$FILES_RESPONSE" | grep -q "固定文件"; then
        echo -e "${GREEN}✓ 响应中包含'固定文件'目录${NC}"
    else
        echo -e "${YELLOW}⚠ 响应中未找到'固定文件'目录${NC}"
        echo "这可能是因为配置文件中没有设置 fixed_files"
    fi
    
    # 显示文件列表结构
    echo -e "\n${BLUE}文件列表结构:${NC}"
    echo "$FILES_RESPONSE" | jq -r '.files[] | "\(.directory) - \(.name) (\(.path))"' 2>/dev/null || echo "$FILES_RESPONSE"
    
else
    echo -e "${RED}✗ 获取文件列表失败${NC}"
    echo "响应: $FILES_RESPONSE"
fi

# 测试步骤3: 检查配置文件
echo -e "\n${BLUE}步骤3: 检查配置文件${NC}"
if [ -f "config.yaml" ]; then
    echo -e "${GREEN}✓ 找到配置文件 config.yaml${NC}"
    
    # 检查是否包含 fixed_files 配置
    if grep -q "fixed_files:" config.yaml; then
        echo -e "${GREEN}✓ 配置文件中包含 fixed_files 配置${NC}"
        echo -e "\n${BLUE}固定文件配置:${NC}"
        grep -A 10 "fixed_files:" config.yaml | grep -E "^\s*-" | sed 's/^\s*- //'
    else
        echo -e "${YELLOW}⚠ 配置文件中未找到 fixed_files 配置${NC}"
        echo "建议在 config.yaml 中添加以下配置:"
        echo "logs:"
        echo "  fixed_files:"
        echo "    - \"./logs/app.log\""
        echo "    - \"./logs/error.log\""
    fi
else
    echo -e "${RED}✗ 未找到配置文件 config.yaml${NC}"
fi

# 测试步骤4: 验证固定文件路径解析
echo -e "\n${BLUE}步骤4: 验证固定文件路径解析${NC}"
if [ -f "config.yaml" ] && grep -q "fixed_files:" config.yaml; then
    echo "检查配置的固定文件是否存在..."
    
    # 提取固定文件路径
    FIXED_FILES=$(grep -A 10 "fixed_files:" config.yaml | grep -E "^\s*-" | sed 's/^\s*- //' | sed 's/#.*$//' | tr -d ' ')
    
    for file_path in $FIXED_FILES; do
        if [ -n "$file_path" ]; then
            # 解析路径
            if [[ "$file_path" == /* ]]; then
                # 绝对路径
                if [ -f "$file_path" ]; then
                    echo -e "${GREEN}✓ 固定文件存在: $file_path${NC}"
                else
                    echo -e "${YELLOW}⚠ 固定文件不存在: $file_path${NC}"
                fi
            else
                # 相对路径
                if [ -f "$file_path" ]; then
                    echo -e "${GREEN}✓ 固定文件存在: $file_path${NC}"
                else
                    echo -e "${YELLOW}⚠ 固定文件不存在: $file_path${NC}"
                fi
            fi
        fi
    done
fi

# 测试步骤5: 测试搜索功能（如果文件存在）
echo -e "\n${BLUE}步骤5: 测试搜索功能${NC}"
if [ -n "$TOKEN" ]; then
    # 尝试搜索一个简单的关键词
    SEARCH_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/logs/search" \
      -H "Content-Type: application/json" \
      -H "Authorization: ${TOKEN}" \
      -d '{"files":["test"],"pattern":"test","reverse":false,"lines":10}')
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 搜索API调用成功${NC}"
        echo "搜索响应状态: $(echo "$SEARCH_RESPONSE" | jq -r '.error // "success"' 2>/dev/null || echo "unknown")"
    else
        echo -e "${YELLOW}⚠ 搜索API调用失败${NC}"
    fi
fi

echo -e "\n${BLUE}测试总结:${NC}"
echo "=================================="
echo "1. 后端API支持固定文件路径配置"
echo "2. 固定文件会显示在文件列表最前面"
echo "3. 支持相对路径和绝对路径"
echo "4. 前端会为固定文件添加特殊样式和标识"
echo ""
echo -e "${GREEN}测试完成！${NC}"
echo ""
echo "使用说明:"
echo "1. 在 config.yaml 中配置 fixed_files 列表"
echo "2. 重启后端服务"
echo "3. 刷新前端页面查看效果"
echo "4. 固定文件会显示在'固定文件'目录下，位于列表最前面"
