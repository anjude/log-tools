#!/bin/bash

echo "=== 测试日志管理工具新功能 ==="

# 创建测试日志目录
echo "1. 创建测试日志目录..."
mkdir -p test-logs/dir1
mkdir -p test-logs/dir2
mkdir -p test-logs/dir3

# 创建测试日志文件
echo "2. 创建测试日志文件..."
echo "2024-01-01 10:00:00 [INFO] Application started" > test-logs/dir1/app.log
echo "2024-01-01 10:01:00 [ERROR] Database connection failed" >> test-logs/dir1/app.log
echo "2024-01-01 10:02:00 [WARN] High memory usage detected" >> test-logs/dir1/app.log

echo "2024-01-01 11:00:00 [INFO] Backup process started" > test-logs/dir2/backup.log
echo "2024-01-01 11:01:00 [SUCCESS] Backup completed successfully" >> test-logs/dir2/backup.log
echo "2024-01-01 11:02:00 [ERROR] Failed to compress backup" >> test-logs/dir2/backup.log

echo "2024-01-01 12:00:00 [DEBUG] User authentication attempt" > test-logs/dir3/auth.log
echo "2024-01-01 12:01:00 [INFO] User login successful" >> test-logs/dir3/auth.log
echo "2024-01-01 12:02:00 [WARN] Multiple failed login attempts" >> test-logs/dir3/auth.log

# 修改配置文件
echo "3. 更新配置文件..."
cat > config.yaml << EOF
# 日志管理工具配置文件

# 服务器配置
server:
  port: 6003
  host: "0.0.0.0"

# 认证配置
auth:
  username: "milk"
  password: "milk@123"

# 日志文件配置
logs:
  # 日志文件目录路径（支持数组，可配置多个目录）
  directories:
    - "./test-logs/dir1"
    - "./test-logs/dir2"
    - "./test-logs/dir3"
  # 兼容旧版本，单个目录配置（如果设置了directories，此配置将被忽略）
  # directory: "./logs"
  # 日志文件名正则匹配模式，支持日期等变量
  pattern: ".*\\.log$"
  # 默认显示日志条数
  default_lines: 200
  # 最大搜索返回条数
  max_search_results: 1000
EOF

echo "4. 构建并启动服务..."
go build -o log-tools main.go

echo "5. 启动服务（后台运行）..."
./log-tools &
SERVER_PID=$!

echo "6. 等待服务启动..."
sleep 3

echo "7. 测试API端点..."
echo "测试获取文件列表..."
curl -s -H "Authorization: milk" "http://localhost:6003/api/logs/files" | jq '.'

echo ""
echo "测试搜索功能..."
echo "搜索包含 'error' 的行:"
curl -s -X POST -H "Content-Type: application/json" -H "Authorization: milk" \
  -d '{"file":"app.log","pattern":"error","reverse":false,"lines":10}' \
  "http://localhost:6003/api/logs/search" | jq '.'

echo ""
echo "搜索包含 'error' 和 'failed' 的行 (AND逻辑):"
curl -s -X POST -H "Content-Type: application/json" -H "Authorization:6003/api/logs/search" | jq '.'

echo ""
echo "搜索包含 'error' 或 'warn' 的行 (OR逻辑):"
curl -s -X POST -H "Content-Type: application/json" -H "Authorization: milk" \
  -d '{"file":"app.log","pattern":"error or warn","reverse":false,"lines":10}' \
  "http://localhost:6003/api/logs/search" | jq '.'

echo ""
echo "搜索双引号包裹的精确短语:"
curl -s -X POST -H "Content-Type: application/json" -H "Authorization: milk" \
  -d '{"file":"app.log","pattern":"\"Database connection failed\"","reverse":false,"lines":10}' \
  "http://localhost:6003/api/logs/search" | jq '.'

echo ""
echo "搜索反引号包裹的字面量:"
curl -s -X POST -H "Content-Type: application/json" -H "Authorization: milk" \
  -d '{"file":"app.log","pattern":"`High memory usage`","reverse":false,"lines":10}' \
  "http://localhost:6003/api/logs/search" | jq '.'

echo ""
echo "搜索没有引号包裹的多个关键词:"
curl -s -X POST -H "Content-Type: application/json" -H "Authorization: milk" \
  -d '{"file":"app.log","pattern":"Application started","reverse":false,"lines":10}' \
  "http://localhost:6003/api/logs/search" | jq '.'

echo ""
echo "8. 停止服务..."
kill $SERVER_PID

echo "9. 清理测试文件..."
rm -rf test-logs
rm -f log-tools

echo "=== 测试完成 ==="
