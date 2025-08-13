# 固定文件路径功能说明

## 功能概述

固定文件路径功能允许用户在配置文件中预先定义特定的日志文件路径，这些文件会显示在日志文件列表的最前面，具有特殊的视觉标识。

## 主要特性

### 1. 配置灵活性
- **支持相对路径**：如 `./logs/app.log`
- **支持绝对路径**：如 `/var/log/nginx/access.log`
- **混合配置**：可以同时配置相对路径和绝对路径

### 2. 优先显示
- 固定文件始终显示在文件列表最前面
- 普通扫描文件显示在固定文件后面
- 保持原有的目录分组和排序逻辑

### 3. 视觉标识
- 固定文件有特殊的黄色背景和边框
- 显示星形图标（⭐）而不是普通文件图标
- 添加"固定"标签标识
- 目录标题显示为"固定文件"

## 配置方法

### 1. 修改配置文件

在 `config.yaml` 文件中添加 `fixed_files` 配置：

```yaml
logs:
  # 日志文件目录路径
  directories:
    - "./logs"
  
  # 确定的日志文件路径列表（支持相对路径和绝对路径）
  fixed_files:
    - "./logs/app.log"
    - "./logs/error.log"
    - "./logs/system.log"
    # 支持绝对路径示例（取消注释并修改为实际路径）
    # - "/var/log/nginx/access.log"
    # - "/var/log/nginx/error.log"
    # - "/var/log/mysql/mysql.log"
  
  # 其他配置...
  pattern: ".*\\.log$"
  default_lines: 200
  max_search_results: 1000
```

### 2. 路径类型说明

#### 相对路径
- 相对于程序运行目录的路径
- 示例：`./logs/app.log`、`logs/error.log`
- 优点：便于项目迁移，路径相对固定

#### 绝对路径
- 系统绝对路径
- 示例：`/var/log/nginx/access.log`、`C:\logs\app.log`
- 优点：路径明确，不受程序运行位置影响

### 3. 配置验证

程序启动时会自动验证配置的固定文件：
- 检查文件是否存在
- 解析相对路径为绝对路径
- 记录验证结果到日志

## 使用场景

### 1. 核心日志文件
- 应用程序的主要日志文件
- 错误日志和访问日志
- 系统关键组件的日志

### 2. 外部系统日志
- Nginx、Apache 等 Web 服务器日志
- 数据库日志（MySQL、PostgreSQL）
- 系统服务日志

### 3. 监控和调试
- 需要经常查看的日志文件
- 性能监控相关的日志
- 安全审计日志

## 技术实现

### 1. 后端实现

#### 配置结构
```go
type LogsConfig struct {
    Directories      []string `mapstructure:"directories"`
    Directory        string   `mapstructure:"directory"`
    FixedFiles       []string `mapstructure:"fixed_files"` // 新增字段
    Pattern          string   `mapstructure:"pattern"`
    DefaultLines     int      `mapstructure:"default_lines"`
    MaxSearchResults int      `mapstructure:"max_search_results"`
}
```

#### 文件处理逻辑
1. 首先处理固定文件路径
2. 解析路径（相对路径转绝对路径）
3. 验证文件存在性
4. 创建固定文件记录
5. 然后处理扫描到的普通文件
6. 按优先级排序（固定文件在前）

#### 路径解析
```go
// 解析路径（支持相对路径和绝对路径）
var resolvedPath string
if filepath.IsAbs(fixedFile) {
    // 绝对路径
    resolvedPath = fixedFile
} else {
    // 相对路径，相对于程序运行目录
    absPath, err := filepath.Abs(fixedFile)
    if err != nil {
        continue
    }
    resolvedPath = absPath
}
```

### 2. 前端实现

#### 特殊样式
```css
/* 固定文件特殊样式 */
.file-item.fixed-file {
    background-color: #fff3cd;
    border-left: 3px solid #ffc107;
}

.file-item.fixed-file:hover {
    background-color: #ffeaa7;
    border-color: #f39c12;
}

.file-item.fixed-file .form-check-input:checked {
    background-color: #ffc107;
    border-color: #ffc107;
}
```

#### 显示逻辑
1. 检查文件是否为固定文件
2. 应用特殊样式类
3. 显示星形图标和"固定"标签
4. 目录标题使用特殊颜色和图标

## 测试和验证

### 1. 测试页面
- `test/test-fixed-files.html`：前端功能演示
- 模拟固定文件和普通文件的显示效果

### 2. API测试脚本
- `test/test-fixed-files-api.sh`：后端功能测试
- 验证配置加载、文件列表获取等功能

### 3. 测试步骤
1. 修改配置文件添加 `fixed_files`
2. 重启后端服务
3. 访问前端页面查看效果
4. 验证固定文件显示在最前面
5. 测试搜索和查看功能

## 注意事项

### 1. 文件存在性
- 配置的固定文件必须实际存在
- 不存在的文件会被自动跳过
- 程序启动时会记录验证结果

### 2. 路径权限
- 确保程序有读取配置文件的权限
- 绝对路径需要相应的文件系统权限
- 相对路径相对于程序运行目录

### 3. 性能影响
- 固定文件数量不宜过多（建议 < 20个）
- 大量固定文件可能影响启动速度
- 建议只配置真正需要的核心日志文件

### 4. 配置维护
- 定期检查固定文件路径的有效性
- 系统迁移时注意更新绝对路径
- 相对路径在项目迁移时更稳定

## 故障排除

### 1. 固定文件不显示
- 检查配置文件语法是否正确
- 验证文件路径是否存在
- 查看后端启动日志中的错误信息

### 2. 路径解析失败
- 检查相对路径是否正确
- 确认程序运行目录
- 验证文件系统权限

### 3. 样式显示异常
- 检查前端CSS是否正确加载
- 验证Bootstrap图标库
- 查看浏览器控制台错误

## 更新日志

### v1.0.0 (2025-01-20)
- 新增固定文件路径配置功能
- 支持相对路径和绝对路径
- 固定文件优先显示
- 特殊视觉标识和样式
- 完整的测试和文档

## 相关文件

- `config.yaml`：配置文件
- `config/config.go`：配置结构定义
- `handlers/logs.go`：日志处理逻辑
- `templates/index.html`：前端页面
- `test/test-fixed-files.html`：测试页面
- `test/test-fixed-files-api.sh`：测试脚本
- `docs/README-固定文件路径功能.md`：本文档
