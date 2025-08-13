# 文件路径Tooltip功能说明

## 功能概述

为了改善用户体验，我们为日志文件列表中的文件路径添加了智能的tooltip显示功能。当文件路径过长时，会自动显示省略号，用户可以通过鼠标悬浮查看完整路径。

## 主要特性

### 1. 智能路径截断
- 文件路径超过200px宽度时自动显示省略号(...)
- 保持界面整洁，避免路径信息占用过多空间
- 支持各种长度的文件路径

### 2. 悬浮显示完整路径
- 鼠标悬浮在路径上时显示完整的tooltip
- tooltip采用半透明黑色背景，白色文字，易于阅读
- 自动计算最佳显示位置，避免超出屏幕边界

### 3. 智能定位
- 优先显示在元素下方
- 如果下方空间不足，自动显示在上方
- 水平居中显示，提供最佳视觉效果

### 4. 平滑动画
- tooltip显示和隐藏都有平滑的淡入淡出效果
- 100ms延迟显示，200ms延迟隐藏，避免闪烁

## 使用方法

### 基本用法
文件路径元素会自动应用tooltip功能，无需额外配置：

```html
<span class="file-path-info" 
      data-full-path="/完整/文件/路径/信息" 
      onmouseenter="showPathTooltip(this, event)" 
      onmouseleave="hidePathTooltip(this)">
    /完整/文件/路径/信息
</span>
```

### 自定义样式
可以通过CSS自定义tooltip的外观：

```css
.file-path-tooltip {
    background: rgba(0, 0, 0, 0.8);  /* 背景色 */
    color: white;                      /* 文字颜色 */
    padding: 8px 12px;                /* 内边距 */
    border-radius: 6px;               /* 圆角 */
    font-size: 11px;                  /* 字体大小 */
    max-width: 400px;                 /* 最大宽度 */
}
```

## 技术实现

### CSS样式
- 使用 `text-overflow: ellipsis` 实现省略号显示
- 设置 `max-width: 200px` 限制路径显示宽度
- 添加 `cursor: help` 提示用户有额外信息

### JavaScript功能
- `showPathTooltip()`: 显示tooltip并计算最佳位置
- `hidePathTooltip()`: 隐藏tooltip并清理DOM元素
- 自动处理多个tooltip的显示和隐藏

### 位置计算
- 使用 `getBoundingClientRect()` 获取元素位置
- 考虑滚动位置和屏幕边界
- 智能选择上方或下方显示

## 测试

### 测试页面
创建了专门的测试页面 `test/test-path-tooltip.html`，包含：
- 短路径测试
- 中等长度路径测试
- 长路径测试
- 超长路径测试

### 启动测试
```bash
# 使用测试脚本
./test/test-path-tooltip.sh

# 或手动启动HTTP服务器
python3 -m http.server 8080
# 然后访问 http://localhost:8080/test/test-path-tooltip.html
```

## 兼容性

- 支持所有现代浏览器
- 使用标准CSS和JavaScript API
- 不依赖第三方库（除了Bootstrap图标）

## 注意事项

1. **性能考虑**: tooltip创建和销毁是轻量级操作，不会影响性能
2. **内存管理**: 自动清理DOM元素，避免内存泄漏
3. **用户体验**: 适当的延迟避免tooltip闪烁
4. **响应式设计**: 自动适应不同屏幕尺寸

## 未来改进

- 支持键盘导航（Tab键切换）
- 添加更多自定义选项（颜色、位置等）
- 支持富文本内容（如格式化路径）
- 添加动画效果选项
