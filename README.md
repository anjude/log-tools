# 日志管理工具 (Log Tools)

一个基于Go语言开发的Web日志管理工具，支持日志文件查看、正则搜索和远程访问管理。

## 功能特性

- 🔐 **用户认证**: 支持用户名密码登录验证
- 📁 **文件管理**: 自动扫描配置目录下的日志文件
- 🔍 **正则搜索**: 支持正则表达式搜索日志内容
- 📱 **响应式界面**: 现代化的Web界面，支持移动端
- ⚡ **高性能**: 基于Go语言，快速高效
- 🔄 **实时更新**: 支持配置文件热重载

## 系统要求

- Linux 系统
- Go 1.21 或更高版本
- 网络访问权限

## 安装步骤

### 1. 克隆项目

```bash
git clone <repository-url>
cd log-tools
```

### 2. 安装依赖

```bash
go mod tidy
```

### 3. 编译项目

```bash
go build -o log-tools main.go
```

### 4. 配置

编辑 `config.yaml` 文件，设置以下配置：

```yaml
# 服务器配置
server:
  port: 6003
  host: "0.0.0.0"

# 认证配置
auth:
  username: "milk"          # 修改为你的用户名
  password: "milk@123"      # 修改为你的密码

# 日志文件配置
logs:
  directory: "./logs"        # 日志文件目录
  pattern: ".*\\.log$"      # 文件名匹配模式
  default_lines: 200        # 默认显示行数
  max_search_results: 1000  # 最大搜索结果数
```

### 5. 运行

```bash
./log-tools
```

## 使用说明

### 1. 访问系统

在浏览器中访问: `http://your-server-ip:6003`

### 2. 登录

使用配置文件中设置的用户名和密码登录

### 3. 查看日志

- 左侧显示可用的日志文件列表
- 点击文件名称查看内容
- 可选择显示的行数（100-1000行）

### 4. 搜索日志

- 在搜索框中输入正则表达式
- 支持复杂的搜索模式，如：`error|ERROR|Exception`
- 可选择正序或倒序显示结果
- 搜索结果包含行号和匹配内容

## 配置文件说明

### 服务器配置

- `port`: 服务端口号
- `host`: 绑定地址，`0.0.0.0` 表示所有网络接口

### 认证配置

- `username`: 登录用户名
- `password`: 登录密码

### 日志配置

- `directory`: 日志文件所在目录
- `pattern`: 文件名匹配模式（支持正则表达式）
- `default_lines`: 默认显示的日志行数
- `max_search_results`: 搜索返回的最大结果数

### 会话配置

- `secret`: 会话密钥（用于加密会话数据）
- `max_age`: 会话最大存活时间（秒）

## 安全建议

1. **修改默认密码**: 首次使用后立即修改默认用户名和密码
2. **网络访问控制**: 建议配置防火墙，限制访问IP范围
3. **HTTPS**: 在生产环境中启用HTTPS
4. **定期更新**: 定期更新Go版本和依赖包

## 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 检查端口占用
   netstat -tlnp | grep 6003
   
   # 修改配置文件中的端口号
   ```

2. **权限不足**
   ```bash
   # 确保程序有读取日志目录的权限
   sudo chmod +r /var/log
   ```

3. **配置文件错误**
   ```bash
   # 检查配置文件语法
   ./log-tools
   ```

### 日志查看

程序运行日志会输出到控制台，包括：
- 配置加载状态
- 服务器启动信息
- 错误和警告信息

## 开发说明

### 项目结构

```
log-tools/
├── main.go              # 主程序入口
├── config/              # 配置管理
│   └── config.go
├── handlers/            # 请求处理器
│   ├── auth.go         # 认证相关
│   ├── logs.go         # 日志相关
│   └── pages.go        # 页面渲染
├── middleware/          # 中间件
│   └── auth.go         # 认证中间件
├── templates/           # HTML模板
│   ├── login.html      # 登录页面
│   └── index.html      # 主页面
├── config.yaml         # 配置文件
├── go.mod              # Go模块文件
└── README.md           # 说明文档
```

### 技术栈

- **后端**: Go + Gin框架
- **前端**: HTML + JavaScript + Bootstrap
- **配置**: YAML + Viper
- **会话**: Gin Sessions

## 许可证

本项目采用 MIT 许可证。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 联系方式

如有问题或建议，请通过以下方式联系：
- 提交 GitHub Issue
- 发送邮件至项目维护者
