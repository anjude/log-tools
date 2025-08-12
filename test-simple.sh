#!/bin/bash

echo "=== 简单功能测试 ==="

# 创建测试目录和文件
echo "1. 创建测试文件..."
mkdir -p test-logs
echo "2024-01-01 10:00:00 [INFO] Test log entry" > test-logs/test.log

# 备份原配置
echo "2. 备份原配置..."
cp config.yaml config.yaml.backup

# 修改配置文件
echo "3. 创建测试配置..."
cat > config.yaml << EOF
server:
  port: 6003
  host: "0.0.0.0"

auth:
  username: "milk"
  password: "milk@123"

logs:
  directories:
    - "./test-logs"
  pattern: ".*\\.log$"
  default_lines: 200
  max_search_results: 1000
EOF

echo "4. 构建程序..."
go build -o log-tools-test main.go

echo "5. 启动服务..."
./log-tools-test &
SERVER_PID=$!

echo "6. 等待服务启动..."
sleep 3

echo "7. 测试文件列表API..."
curl -s -H "Authorization: milk" "http://localhost:6003/api/logs/files" | jq '.'

echo ""
echo "8. 测试文件内容API..."
curl -s -H "Authorization: milk" "http://localhost:6003/api/logs/content?file=test.log&lines=5" | jq '.'

echo ""
echo "9. 停止服务..."
kill $SERVER_PID

echo "10. 恢复原配置..."
mv config.yaml.backup config.yaml

echo "11. 清理..."
rm -rf test-logs log-tools-test

echo "=== 测试完成 ==="
