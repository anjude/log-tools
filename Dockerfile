# 多阶段构建Dockerfile
FROM golang:1.21-alpine AS builder

# 设置工作目录
WORKDIR /app

# 复制go mod文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o log-tools main.go

# 运行阶段
FROM alpine:latest

# 安装ca-certificates用于HTTPS
RUN apk --no-cache add ca-certificates

# 创建非root用户
RUN addgroup -g 1001 -S log-tools && \
    adduser -u 1001 -S log-tools -G log-tools

# 设置工作目录
WORKDIR /app

# 从构建阶段复制二进制文件
COPY --from=builder /app/log-tools .

# 复制配置文件和模板
COPY --from=builder /app/config.yaml .
COPY --from=builder /app/templates ./templates

# 创建日志目录
RUN mkdir -p /var/log && \
    chown -R log-tools:log-tools /app /var/log

# 切换到非root用户
USER log-tools

# 暴露端口
EXPOSE 6003

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:6003/api/check-auth || exit 1

# 启动应用
CMD ["./log-tools"]
