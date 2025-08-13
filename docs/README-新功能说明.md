# 日志管理工具新功能说明

## 新增功能概述

本次更新为日志管理工具添加了以下重要功能：

### 1. 默认选择第一个日志文件
- 页面加载完成后，系统会自动选择并显示第一个可用的日志文件
- 用户无需手动点击选择，提升了使用体验
- 如果用户之前已经选择了文件，则不会自动覆盖

### 2. 支持多个日志文件目录
- 配置文件现在支持 `directories` 数组字段，可以配置多个日志目录
- 系统会扫描所有配置的目录，收集符合条件的日志文件
- 保持向后兼容，原有的 `directory` 字段仍然有效
- 文件列表会显示每个文件的来源目录

**配置文件示例：**
```yaml
logs:
  # 支持多个日志目录
  directories:
    - "./logs"
    - "/var/log"
    - "/tmp/logs"
  # 兼容旧版本
  # directory: "./logs"
```

### 3. 增强的搜索功能

#### 3.1 双引号包裹的精确搜索
- 使用双引号包裹的字符串会被当作精确短语进行搜索
- 例如：`"Database connection failed"` 会搜索包含完整短语的行

#### 3.2 反引号包裹的字面量搜索
- 使用反引号包裹的字符串会被当作字面量进行搜索，不考虑转义字符
- 例如：`` `High memory usage` `` 会直接搜索包含该字符串的行
- 特别适用于包含特殊字符的搜索条件

#### 3.3 无引号包裹的智能搜索
- 没有引号包裹的搜索条件会被当作字面量处理
- 系统默认使用 AND 逻辑，所有关键词都必须匹配
- 例如：`error exception` 会搜索同时包含 "error" 和 "exception" 的行
- 例如：`database connection` 会搜索同时包含 "database" 和 "connection" 的行

#### 3.4 逻辑连接符支持
- 支持 `and` 和 `or` 逻辑连接符
- 例如：`"error" or "warn"` 会搜索包含 "error" 或 "warn" 的行
- 例如：`"error" and "failed"` 会搜索同时包含 "error" 和 "failed" 的行
- 例如：`database and "connection failed"` 会搜索同时包含 "database" 和完整短语 "connection failed" 的行

### 4. 搜索语法示例

| 搜索模式 | 说明 | 匹配结果 |
|---------|------|----------|
| `error` | 单个字面量 | 包含 "error" 的行 |
| `error exception` | 多个字面量（AND逻辑） | 同时包含 "error" 和 "exception" 的行 |
| `"Database connection failed"` | 精确短语 | 包含完整短语 "Database connection failed" 的行 |
| `` `High memory usage` `` | 字面量 | 包含字符串 "High memory usage" 的行 |
| `"error" or "warn"` | OR逻辑 | 包含 "error" 或 "warn" 的行 |
| `"error" and "failed"` | AND逻辑 | 同时包含 "error" 和 "failed" 的行 |
| `database and "connection failed"` | 混合逻辑 | 同时包含 "database" 和完整短语 "connection failed" 的行 |

## 技术实现

### 后端改进
- 重构了配置管理，支持多目录配置
- 增强了搜索模式解析器，支持反引号字面量
- 优化了文件路径验证，支持多目录安全验证
- 改进了搜索算法，支持更复杂的逻辑组合

### 前端改进
- 自动选择第一个日志文件
- 增强的搜索界面，支持多种搜索语法
- 改进的文件列表显示，显示文件来源目录
- 优化的搜索提示和帮助信息

## 使用方法

### 1. 配置多个日志目录
编辑 `config.yaml` 文件：
```yaml
logs:
  directories:
    - "./logs"
    - "/var/log"
    - "/tmp/logs"
  pattern: ".*\\.log$"
```

### 2. 使用搜索功能
在搜索框中输入搜索条件：
- 普通关键词：`error exception`
- 精确短语：`"Database connection failed"`
- 字面量：`` `High memory usage` ``
- 逻辑组合：`"error" or "warn"`

### 3. 查看搜索结果
- 搜索结果会高亮显示匹配的关键词
- 显示匹配的行数和行号
- 支持倒序显示和行数限制

## 兼容性说明

- 完全向后兼容，原有的配置文件仍然有效
- 如果同时配置了 `directories` 和 `directory`，优先使用 `directories`
- 搜索功能保持原有API接口不变，只是增强了功能

## 注意事项

1. 反引号包裹的字符串会被当作字面量处理，不会进行正则表达式转义
2. 多个日志目录的扫描是并行的，但文件列表会按修改时间排序
3. 搜索功能支持的最大结果数由配置文件中的 `max_search_results` 控制
4. 文件路径验证确保安全性，防止路径遍历攻击

## 测试

运行测试脚本验证新功能：
```bash
chmod +x test-new-features.sh
./test-new-features.sh
```

测试脚本会：
- 创建测试日志目录和文件
- 启动服务并测试各种搜索功能
- 验证多目录配置
- 清理测试文件
