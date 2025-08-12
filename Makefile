# 日志管理工具 Makefile

# 变量定义
BINARY_NAME=log-tools
BUILD_DIR=build
MAIN_FILE=main.go

# 默认目标
.PHONY: all
all: clean build

# 清理构建目录
.PHONY: clean
clean:
	@echo "清理构建目录..."
	@rm -rf $(BUILD_DIR)
	@rm -f $(BINARY_NAME)

# 安装依赖
.PHONY: deps
deps:
	@echo "安装依赖..."
	@go mod tidy
	@go mod download

# 构建项目
.PHONY: build
build: deps
	@echo "构建项目..."
	@mkdir -p $(BUILD_DIR)
	@go build -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_FILE)
	@echo "构建完成: $(BUILD_DIR)/$(BINARY_NAME)"

# 构建Linux版本
.PHONY: build-linux
build-linux: deps
	@echo "构建Linux版本..."
	@mkdir -p $(BUILD_DIR)
	@GOOS=linux GOARCH=amd64 go build -o $(BUILD_DIR)/$(BINARY_NAME)-linux $(MAIN_FILE)
	@echo "构建完成: $(BUILD_DIR)/$(BINARY_NAME)-linux"

# 运行项目
.PHONY: run
run: build
	@echo "运行项目..."
	@cd $(BUILD_DIR) && ./$(BINARY_NAME)

# 开发模式运行（自动重载）
.PHONY: dev
dev: deps
	@echo "开发模式运行..."
	@go run $(MAIN_FILE)

# 测试
.PHONY: test
test: deps
	@echo "运行测试..."
	@go test ./...

# 代码检查
.PHONY: lint
lint: deps
	@echo "代码检查..."
	@go vet ./...
	@gofmt -l .

# 创建发布包
.PHONY: release
release: build-linux
	@echo "创建发布包..."
	@cd $(BUILD_DIR) && tar -czf $(BINARY_NAME)-linux.tar.gz $(BINARY_NAME)-linux
	@echo "发布包创建完成: $(BUILD_DIR)/$(BINARY_NAME)-linux.tar.gz"

# 安装到系统
.PHONY: install
install: build
	@echo "安装到系统..."
	@sudo cp $(BUILD_DIR)/$(BINARY_NAME) /usr/local/bin/
	@sudo chmod +x /usr/local/bin/$(BINARY_NAME)
	@echo "安装完成，可通过 '$(BINARY_NAME)' 命令运行"

# 卸载
.PHONY: uninstall
uninstall:
	@echo "卸载..."
	@sudo rm -f /usr/local/bin/$(BINARY_NAME)
	@echo "卸载完成"

# 帮助信息
.PHONY: help
help:
	@echo "可用的目标:"
	@echo "  all        - 清理并构建项目"
	@echo "  build      - 构建项目"
	@echo "  build-linux- 构建Linux版本"
	@echo "  clean      - 清理构建目录"
	@echo "  deps       - 安装依赖"
	@echo "  run        - 构建并运行项目"
	@echo "  dev        - 开发模式运行"
	@echo "  test       - 运行测试"
	@echo "  lint       - 代码检查"
	@echo "  release    - 创建发布包"
	@echo "  install    - 安装到系统"
	@echo "  uninstall  - 从系统卸载"
	@echo "  help       - 显示此帮助信息"