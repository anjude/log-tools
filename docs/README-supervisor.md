# Log-Tools Supervisor 配置说明

本文档说明如何在Linux系统上使用Supervisor来管理log-tools服务。

## 文件说明

- `supervisor.conf` - Supervisor主配置文件
- `install-supervisor.sh` - 自动安装脚本
- `uninstall-supervisor.sh` - 卸载脚本

## 快速开始

### 1. 构建Linux版本

首先构建Linux版本的二进制文件：

```bash
make build-linux
```

### 2. 安装Supervisor服务

运行安装脚本（需要root权限）：

```bash
sudo chmod +x install-supervisor.sh
sudo ./install-supervisor.sh
```

### 3. 验证服务状态

```bash
supervisorctl status log-tools
```

## 手动安装步骤

如果您想手动安装，请按以下步骤操作：

### 1. 安装Supervisor

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install supervisor
```

**CentOS/RHEL:**
```bash
sudo yum install supervisor
sudo systemctl enable supervisord
sudo systemctl start supervisord
```

### 2. 创建应用目录

```bash
sudo mkdir -p /opt/log-tools
sudo mkdir -p /var/log/supervisor
```

### 3. 复制应用文件

```bash
# 复制二进制文件
sudo cp ./build/log-tools-linux /opt/log-tools/log-tools

# 复制配置文件
sudo cp ./config.yaml /opt/log-tools/

# 复制模板文件
sudo cp -r ./templates /opt/log-tools/

# 设置权限
sudo chmod +x /opt/log-tools/log-tools
sudo chown -R root:root /opt/log-tools
```

### 4. 配置Supervisor

```bash
# 复制配置文件
sudo cp ./supervisor.conf /etc/supervisor/conf.d/log-tools.conf

# 重新加载配置
sudo supervisorctl reread
sudo supervisorctl update
```

### 5. 启动服务

```bash
sudo supervisorctl start log-tools
```

## 服务管理命令

### 查看服务状态
```bash
supervisorctl status log-tools
```

### 启动服务
```bash
supervisorctl start log-tools
```

### 停止服务
```bash
supervisorctl stop log-tools
```

### 重启服务
```bash
supervisorctl restart log-tools
```

### 查看日志
```bash
# 查看应用日志
tail -f /var/log/supervisor/log-tools.log

# 查看错误日志
tail -f /var/log/supervisor/log-tools-error.log

# 查看supervisor日志
tail -f /var/log/supervisor/supervisord.log
```

### 重新加载配置
```bash
supervisorctl reread
supervisorctl update
```

## 配置文件说明

### supervisor.conf 主要配置项

- **command**: 启动命令，指向log-tools二进制文件
- **directory**: 工作目录
- **autostart**: 是否自动启动
- **autorestart**: 是否自动重启
- **startsecs**: 启动后等待多少秒认为启动成功
- **startretries**: 启动失败重试次数
- **stdout_logfile**: 标准输出日志文件
- **stderr_logfile**: 错误输出日志文件
- **environment**: 环境变量设置

## 故障排除

### 1. 服务无法启动

检查日志文件：
```bash
tail -f /var/log/supervisor/log-tools-error.log
```

### 2. 权限问题

确保文件权限正确：
```bash
sudo chown -R root:root /opt/log-tools
sudo chmod +x /opt/log-tools/log-tools
```

### 3. 端口占用

检查6003端口是否被占用：
```bash
netstat -tlnp | grep 6003
```

### 4. 配置文件问题

检查配置文件语法：
```bash
supervisord -n -c /etc/supervisor/supervisord.conf
```

## 卸载服务

运行卸载脚本：

```bash
sudo chmod +x uninstall-supervisor.sh
sudo ./uninstall-supervisor.sh
```

## 注意事项

1. **安全性**: 当前配置使用root用户运行，生产环境建议创建专用用户
2. **日志轮转**: 日志文件会自动轮转，避免占用过多磁盘空间
3. **自动重启**: 服务崩溃后会自动重启
4. **端口配置**: 默认使用6003端口，可在config.yaml中修改

## 生产环境建议

1. 创建专用用户运行服务
2. 配置防火墙规则
3. 设置日志轮转策略
4. 配置监控和告警
5. 定期备份配置文件

## 支持的操作系统

- Ubuntu 18.04+
- Debian 9+
- CentOS 7+
- RHEL 7+
- Fedora 28+

## 联系支持

如果遇到问题，请检查：
1. 系统日志
2. Supervisor日志
3. 应用日志
4. 网络连接
5. 文件权限
