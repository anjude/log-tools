@echo off
chcp 65001 >nul
echo 🚀 启动日志管理工具...

REM 检查Go是否安装
go version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未安装Go语言环境
    echo 请先安装Go 1.21或更高版本
    pause
    exit /b 1
)

REM 获取Go版本
for /f "tokens=3" %%i in ('go version') do set GO_VERSION=%%i
set GO_VERSION=%GO_VERSION:go=%

echo ✅ Go版本检查通过: %GO_VERSION%

REM 安装依赖
echo 📦 安装Go依赖...
go mod tidy

REM 检查配置文件
if not exist "config.yaml" (
    echo ❌ 错误: 配置文件config.yaml不存在
    pause
    exit /b 1
)

echo ✅ 配置文件检查通过

REM 启动应用
echo 🌐 启动Web服务器...
echo 访问地址: http://localhost:6003
echo 默认用户: milk
echo 默认密码: milk@123
echo.
echo 按 Ctrl+C 停止服务
echo.

go run main.go

pause
