# 图标文件说明

## 当前图标
- `favicon.svg` - SVG格式的网站图标，支持现代浏览器

## 生成ICO图标
为了获得最佳的浏览器兼容性，建议将SVG转换为ICO格式：

### 方法1：在线转换工具
1. 访问 https://convertio.co/svg-ico/ 或 https://favicon.io/favicon-converter/
2. 上传 `favicon.svg` 文件
3. 下载生成的ICO文件
4. 重命名为 `favicon.ico` 并放在此目录

### 方法2：使用ImageMagick
```bash
# 安装ImageMagick后执行
magick favicon.svg -resize 32x32 favicon.ico
```

### 方法3：使用GIMP或Photoshop
1. 打开SVG文件
2. 导出为ICO格式
3. 设置合适的尺寸（建议32x32像素）

## 图标设计说明
当前图标设计包含：
- 蓝色渐变背景圆形
- 白色文档图标
- 蓝色文本行
- 白色搜索图标

图标颜色与网站主题保持一致（#667eea 到 #764ba2 的渐变）。
