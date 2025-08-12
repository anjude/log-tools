package handlers

import (
	"bufio"
	"fmt"
	"log-tools/config"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
)

// LogFile 日志文件信息
type LogFile struct {
	Path    string `json:"path"`
	Name    string `json:"name"`
	Size    int64  `json:"size"`
	ModTime string `json:"mod_time"`
}

// GetLogFiles 获取日志文件列表
func GetLogFiles(c *gin.Context) {
	cfg := config.GetConfig()

	// 添加调试信息
	fmt.Printf("配置的日志目录: %s\n", cfg.Logs.Directory)
	fmt.Printf("配置的文件模式: %s\n", cfg.Logs.Pattern)

	files, err := cfg.GetLogFiles()
	if err != nil {
		fmt.Printf("获取日志文件错误: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": fmt.Sprintf("获取日志文件失败: %v", err),
		})
		return
	}

	fmt.Printf("找到的原始文件路径: %v\n", files)

	var logFiles []LogFile
	for _, file := range files {
		info, err := os.Stat(file)
		if err != nil {
			fmt.Printf("获取文件信息失败 %s: %v\n", file, err)
			continue
		}

		// 获取相对于日志目录的路径
		relPath, err := filepath.Rel(cfg.Logs.Directory, file)
		if err != nil {
			// 如果无法获取相对路径，使用文件名
			relPath = filepath.Base(file)
		}

		logFile := LogFile{
			Path:    relPath, // 使用相对路径
			Name:    filepath.Base(file),
			Size:    info.Size(),
			ModTime: info.ModTime().Format("2006-01-02 15:04:05"),
		}

		fmt.Printf("处理文件: %+v\n", logFile)
		logFiles = append(logFiles, logFile)
	}

	// 按修改时间倒序排序
	sort.Slice(logFiles, func(i, j int) bool {
		return logFiles[i].ModTime > logFiles[j].ModTime
	})

	fmt.Printf("最终返回的文件列表: %+v\n", logFiles)

	c.JSON(http.StatusOK, gin.H{
		"files": logFiles,
	})
}

// GetLogContent 获取日志内容
func GetLogContent(c *gin.Context) {
	filePath := c.Query("file")
	linesStr := c.DefaultQuery("lines", "200")

	if filePath == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "文件路径不能为空",
		})
		return
	}

	// 添加调试信息
	fmt.Printf("请求的文件路径: %s\n", filePath)

	// 验证文件路径安全性
	cfg := config.GetConfig()
	absLogDir, err := filepath.Abs(cfg.Logs.Directory)
	if err != nil {
		fmt.Printf("获取日志目录绝对路径失败: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "服务器配置错误",
		})
		return
	}

	// 清理文件路径，移除可能的路径遍历攻击
	cleanPath := filepath.Clean(filePath)
	
	// 如果提供的是相对路径，尝试在日志目录中查找
	if !filepath.IsAbs(cleanPath) {
		cleanPath = filepath.Join(cfg.Logs.Directory, cleanPath)
	}
	
	// 获取绝对路径
	absFilePath, err := filepath.Abs(cleanPath)
	if err != nil {
		fmt.Printf("获取文件绝对路径失败: %v\n", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "文件路径格式错误",
		})
		return
	}

	// 安全检查：确保文件路径在日志目录内
	if !strings.HasPrefix(absFilePath, absLogDir) {
		fmt.Printf("文件路径安全检查失败: %s 不在目录 %s 内\n", absFilePath, absLogDir)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "文件路径不在允许的目录内",
		})
		return
	}

	// 检查文件是否存在
	if _, err := os.Stat(absFilePath); os.IsNotExist(err) {
		fmt.Printf("文件不存在: %s\n", absFilePath)
		c.JSON(http.StatusNotFound, gin.H{
			"error": fmt.Sprintf("文件不存在: %s", filepath.Base(absFilePath)),
		})
		return
	}

	lines, err := strconv.Atoi(linesStr)
	if err != nil {
		lines = 200
	}

	if lines > cfg.Logs.MaxSearchResults {
		lines = cfg.Logs.MaxSearchResults
	}

	// 读取文件最后N行
	content, err := readLastNLines(absFilePath, lines)
	if err != nil {
		fmt.Printf("读取文件失败: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": fmt.Sprintf("读取日志文件失败: %v", err),
		})
		return
	}

	fmt.Printf("成功读取文件 %s，共 %d 行\n", absFilePath, len(content))

	c.JSON(http.StatusOK, gin.H{
		"content": content,
		"file":    filepath.Base(absFilePath),
		"lines":   len(content),
	})
}

// SearchRequest 搜索请求结构
type SearchRequest struct {
	File    string `json:"file" binding:"required"`
	Pattern string `json:"pattern" binding:"required"`
	Reverse bool   `json:"reverse"`
}

// SearchResult 搜索结果结构
type SearchResult struct {
	LineNumber int    `json:"line_number"`
	Content    string `json:"content"`
	File       string `json:"file"`
}

// SearchLogs 搜索日志
func SearchLogs(c *gin.Context) {
	var req SearchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "请求参数错误",
		})
		return
	}

	// 添加调试信息
	fmt.Printf("搜索请求: 文件=%s, 模式=%s, 倒序=%v\n", req.File, req.Pattern, req.Reverse)

	// 验证文件路径安全性
	cfg := config.GetConfig()
	absLogDir, err := filepath.Abs(cfg.Logs.Directory)
	if err != nil {
		fmt.Printf("获取日志目录绝对路径失败: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "服务器配置错误",
		})
		return
	}

	// 清理文件路径，移除可能的路径遍历攻击
	cleanPath := filepath.Clean(req.File)
	
	// 如果提供的是相对路径，尝试在日志目录中查找
	if !filepath.IsAbs(cleanPath) {
		cleanPath = filepath.Join(cfg.Logs.Directory, cleanPath)
	}
	
	// 获取绝对路径
	absFilePath, err := filepath.Abs(cleanPath)
	if err != nil {
		fmt.Printf("获取文件绝对路径失败: %v\n", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "文件路径格式错误",
		})
		return
	}

	// 安全检查：确保文件路径在日志目录内
	if !strings.HasPrefix(absFilePath, absLogDir) {
		fmt.Printf("文件路径安全检查失败: %s 不在目录 %s 内\n", absFilePath, absLogDir)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "文件路径不在允许的目录内",
		})
		return
	}

	// 检查文件是否存在
	if _, err := os.Stat(absFilePath); os.IsNotExist(err) {
		fmt.Printf("搜索文件不存在: %s\n", absFilePath)
		c.JSON(http.StatusNotFound, gin.H{
			"error": fmt.Sprintf("文件不存在: %s", filepath.Base(absFilePath)),
		})
		return
	}

	// 编译正则表达式
	regex, err := regexp.Compile(req.Pattern)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("正则表达式错误: %v", err),
		})
		return
	}

	// 搜索日志
	results, err := searchInFile(absFilePath, regex, cfg.Logs.MaxSearchResults)
	if err != nil {
		fmt.Printf("搜索文件失败: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": fmt.Sprintf("搜索失败: %v", err),
		})
		return
	}

	// 排序结果
	if req.Reverse {
		sort.Slice(results, func(i, j int) bool {
			return results[i].LineNumber > results[j].LineNumber
		})
	} else {
		sort.Slice(results, func(i, j int) bool {
			return results[i].LineNumber < results[j].LineNumber
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"results": results,
		"count":   len(results),
		"file":    filepath.Base(absFilePath),
	})
}

// readLastNLines 读取文件最后N行
func readLastNLines(filePath string, n int) ([]string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		lines = append(lines, scanner.Text())
		if len(lines) > n {
			lines = lines[1:] // 保持最新的N行
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return lines, nil
}

// searchInFile 在文件中搜索
func searchInFile(filePath string, regex *regexp.Regexp, maxResults int) ([]SearchResult, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var results []SearchResult
	scanner := bufio.NewScanner(file)
	lineNumber := 0

	for scanner.Scan() {
		lineNumber++
		line := scanner.Text()

		if regex.MatchString(line) {
			results = append(results, SearchResult{
				LineNumber: lineNumber,
				Content:    strings.TrimSpace(line),
				File:       filePath,
			})

			if len(results) >= maxResults {
				break
			}
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return results, nil
}
