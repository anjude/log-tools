package handlers

import (
	"bufio"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/anjude/log-tools/config"

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
		var relPath string
		var baseDir string

		// 确定文件所属的日志目录
		if len(cfg.Logs.Directories) > 0 {
			// 使用多目录配置
			for _, dir := range cfg.Logs.Directories {
				if strings.HasPrefix(file, dir) {
					baseDir = dir
					break
				}
			}
		} else if cfg.Logs.Directory != "" {
			// 使用单目录配置
			baseDir = cfg.Logs.Directory
		} else {
			// 默认目录
			baseDir = "./logs"
		}

		if baseDir != "" {
			relPath, err = filepath.Rel(baseDir, file)
			if err != nil {
				// 如果无法获取相对路径，使用文件名
				relPath = filepath.Base(file)
			}
		} else {
			// 如果无法确定基础目录，使用文件名
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
	reverseStr := c.DefaultQuery("reverse", "false")

	if filePath == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "文件路径不能为空",
		})
		return
	}

	// 添加调试信息
	fmt.Printf("请求的文件路径: %s\n", filePath)

	// 验证文件路径安全性
	absFilePath, err := validateFilePath(filePath)
	if err != nil {
		fmt.Printf("文件路径验证失败: %v\n", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
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

	if lines > config.GetConfig().Logs.MaxSearchResults {
		lines = config.GetConfig().Logs.MaxSearchResults
	}

	reverse := reverseStr == "true"

	// 读取文件最后N行
	content, err := readLastNLines(absFilePath, lines, reverse)
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
	Lines   int    `json:"lines"`
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
	fmt.Printf("搜索请求: 文件=%s, 模式=%s, 倒序=%v, 行数=%d\n", req.File, req.Pattern, req.Reverse, req.Lines)

	// 验证文件路径安全性
	absFilePath, err := validateFilePath(req.File)
	if err != nil {
		fmt.Printf("文件路径验证失败: %v\n", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
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

	// 解析搜索模式
	searchQuery, err := parseSearchPattern(req.Pattern)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("搜索模式解析错误: %v", err),
		})
		return
	}

	// 搜索日志
	results, err := searchInFileAdvanced(absFilePath, searchQuery, config.GetConfig().Logs.MaxSearchResults, req.Reverse, req.Lines)
	if err != nil {
		fmt.Printf("搜索文件失败: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": fmt.Sprintf("搜索失败: %v", err),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"results": results,
		"count":   len(results),
		"file":    filepath.Base(absFilePath),
	})
}

// SearchQuery 搜索查询结构
type SearchQuery struct {
	Keywords []SearchKeyword
	Logic    string // "and" 或 "or"
}

// SearchKeyword 搜索关键词结构
type SearchKeyword struct {
	Value string
	Type  string // "exact" 或 "word"
}

// parseSearchPattern 解析搜索模式
func parseSearchPattern(pattern string) (*SearchQuery, error) {
	query := &SearchQuery{
		Keywords: []SearchKeyword{},
		Logic:    "and", // 默认为and逻辑
	}

	// 添加调试信息
	fmt.Printf("开始解析搜索模式: '%s'\n", pattern)

	// 分割模式为token
	tokens := parseTokens(pattern)
	fmt.Printf("解析出的tokens: %+v\n", tokens)

	if len(tokens) == 0 {
		return nil, fmt.Errorf("搜索模式为空")
	}

	// 处理逻辑连接符
	for i, token := range tokens {
		fmt.Printf("处理token %d: %+v\n", i, token)
		if token.Type == "operator" {
			if i == 0 || i == len(tokens)-1 {
				return nil, fmt.Errorf("逻辑连接符不能出现在开头或结尾")
			}
			if token.Value == "or" {
				query.Logic = "or"
			}
		} else if token.Type == "exact" || token.Type == "word" || token.Type == "literal" {
			query.Keywords = append(query.Keywords, SearchKeyword{
				Value: token.Value,
				Type:  token.Type,
			})
		}
	}

	if len(query.Keywords) == 0 {
		return nil, fmt.Errorf("没有找到有效的搜索关键词")
	}

	fmt.Printf("最终查询: %+v\n", query)
	return query, nil
}

// Token 解析后的token结构
type Token struct {
	Value string
	Type  string // "exact", "word", "operator"
}

// parseTokens 解析搜索模式为token
func parseTokens(pattern string) []Token {
	var tokens []Token
	var current strings.Builder
	inQuotes := false
	inBackticks := false

	for i := 0; i < len(pattern); i++ {
		char := pattern[i]

		if char == '"' && !inBackticks {
			if inQuotes {
				// 结束双引号
				if current.Len() > 0 {
					tokens = append(tokens, Token{
						Value: strings.TrimSpace(current.String()),
						Type:  "exact",
					})
					current.Reset()
				}
				inQuotes = false
			} else {
				// 开始双引号
				if current.Len() > 0 {
					// 保存引号前的普通文本
					text := strings.TrimSpace(current.String())
					if text != "" {
						// 检查是否是逻辑连接符
						if isLogicOperator(text) {
							tokens = append(tokens, Token{
								Value: text,
								Type:  "operator",
							})
						} else {
							// 将普通文本当作字面量处理
							tokens = append(tokens, Token{
								Value: text,
								Type:  "literal",
							})
						}
					}
					current.Reset()
				}
				inQuotes = true
			}
		} else if char == '`' && !inQuotes {
			if inBackticks {
				// 结束反引号
				if current.Len() > 0 {
					tokens = append(tokens, Token{
						Value: strings.TrimSpace(current.String()),
						Type:  "literal", // 字面量类型，不考虑转义
					})
					current.Reset()
				}
				inBackticks = false
			} else {
				// 开始反引号
				if current.Len() > 0 {
					// 保存反引号前的普通文本
					text := strings.TrimSpace(current.String())
					if text != "" {
						// 检查是否是逻辑连接符
						if isLogicOperator(text) {
							tokens = append(tokens, Token{
								Value: text,
								Type:  "operator",
							})
						} else {
							// 将普通文本当作字面量处理
							tokens = append(tokens, Token{
								Value: text,
								Type:  "literal",
							})
						}
					}
					current.Reset()
				}
				inBackticks = true
			}
		} else if char == ' ' && !inQuotes && !inBackticks {
			// 空格分割（不在引号内）
			if current.Len() > 0 {
				text := strings.TrimSpace(current.String())
				if text != "" {
					// 检查是否是逻辑连接符
					if isLogicOperator(text) {
						tokens = append(tokens, Token{
							Value: text,
							Type:  "operator",
						})
					} else {
						// 将普通文本当作字面量处理
						tokens = append(tokens, Token{
							Value: text,
							Type:  "literal",
						})
					}
				}
				current.Reset()
			}
		} else {
			current.WriteByte(char)
		}
	}

	// 处理最后一个token
	if current.Len() > 0 {
		text := strings.TrimSpace(current.String())
		if text != "" {
			if inQuotes {
				tokens = append(tokens, Token{
					Value: text,
					Type:  "exact",
				})
			} else if inBackticks {
				tokens = append(tokens, Token{
					Value: text,
					Type:  "literal",
				})
			} else if isLogicOperator(text) {
				tokens = append(tokens, Token{
					Value: text,
					Type:  "operator",
				})
			} else {
				// 将普通文本当作字面量处理
				tokens = append(tokens, Token{
					Value: text,
					Type:  "literal",
				})
			}
		}
	}

	return tokens
}

// isLogicOperator 检查是否是逻辑连接符
func isLogicOperator(text string) bool {
	lower := strings.ToLower(strings.TrimSpace(text))
	return lower == "and" || lower == "or"
}

// searchInFileAdvanced 高级文件搜索
func searchInFileAdvanced(filePath string, query *SearchQuery, maxResults int, reverse bool, maxLines int) ([]SearchResult, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var results []SearchResult
	scanner := bufio.NewScanner(file)
	lineNumber := 0
	var allLines []string

	// 读取所有行
	for scanner.Scan() {
		lineNumber++
		allLines = append(allLines, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	// 限制搜索行数
	if maxLines > 0 && len(allLines) > maxLines {
		if reverse {
			allLines = allLines[len(allLines)-maxLines:]
		} else {
			allLines = allLines[:maxLines]
		}
	}

	// 搜索匹配的行
	for i, line := range allLines {
		lineNum := i + 1
		if reverse {
			lineNum = len(allLines) - i
		}

		if matchesSearchQuery(line, query) {
			results = append(results, SearchResult{
				LineNumber: lineNum,
				Content:    strings.TrimSpace(line),
				File:       filePath,
			})

			if len(results) >= maxResults {
				break
			}
		}
	}

	// 按行号排序
	if reverse {
		sort.Slice(results, func(i, j int) bool {
			return results[i].LineNumber > results[j].LineNumber
		})
	} else {
		sort.Slice(results, func(i, j int) bool {
			return results[i].LineNumber < results[j].LineNumber
		})
	}

	return results, nil
}

// matchesSearchQuery 检查行是否匹配搜索查询
func matchesSearchQuery(line string, query *SearchQuery) bool {
	if len(query.Keywords) == 0 {
		return false
	}

	if query.Logic == "or" {
		// OR逻辑：任一关键词匹配即可
		for _, keyword := range query.Keywords {
			if matchesKeyword(line, keyword) {
				return true
			}
		}
		return false
	} else {
		// AND逻辑：所有关键词都必须匹配
		for _, keyword := range query.Keywords {
			if !matchesKeyword(line, keyword) {
				return false
			}
		}
		return true
	}
}

// matchesKeyword 检查行是否匹配单个关键词
func matchesKeyword(line string, keyword SearchKeyword) bool {
	lineLower := strings.ToLower(line)
	keywordLower := strings.ToLower(keyword.Value)

	if keyword.Type == "exact" {
		// 精确匹配：包含完整的短语
		return strings.Contains(lineLower, keywordLower)
	} else if keyword.Type == "literal" {
		// 字面量匹配：直接包含字符串，不考虑转义
		return strings.Contains(lineLower, keywordLower)
	} else {
		// 单词匹配：作为完整单词出现
		words := strings.Fields(lineLower)
		for _, word := range words {
			if word == keywordLower {
				return true
			}
		}
		return false
	}
}

// readLastNLines 读取文件最后N行
func readLastNLines(filePath string, n int, reverse bool) ([]string, error) {
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

	// 如果需要倒序，反转数组
	if reverse {
		for i, j := 0, len(lines)-1; i < j; i, j = i+1, j-1 {
			lines[i], lines[j] = lines[j], lines[i]
		}
	}

	return lines, nil
}

// searchInFile 在文件中搜索（保留原有函数以兼容性）
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

// getLogDirectories 获取日志目录列表
func getLogDirectories() []string {
	cfg := config.GetConfig()
	var directories []string

	if len(cfg.Logs.Directories) > 0 {
		directories = cfg.Logs.Directories
	} else if cfg.Logs.Directory != "" {
		directories = []string{cfg.Logs.Directory}
	} else {
		directories = []string{"./logs"}
	}

	return directories
}

// validateFilePath 验证文件路径安全性
func validateFilePath(filePath string) (string, error) {
	// 清理文件路径，移除可能的路径遍历攻击
	cleanPath := filepath.Clean(filePath)

	// 添加调试信息
	fmt.Printf("原始文件路径: %s\n", filePath)
	fmt.Printf("清理后路径: %s\n", cleanPath)

	// 获取日志目录列表
	directories := getLogDirectories()
	fmt.Printf("搜索目录: %v\n", directories)

	// 如果提供的是相对路径，尝试在所有日志目录中查找
	if !filepath.IsAbs(cleanPath) {
		for _, dir := range directories {
			fullPath := filepath.Join(dir, cleanPath)
			fmt.Printf("尝试路径: %s\n", fullPath)

			if _, err := os.Stat(fullPath); err == nil {
				// 文件存在，验证路径安全性
				absFilePath, err := filepath.Abs(fullPath)
				if err != nil {
					fmt.Printf("获取绝对路径失败: %v\n", err)
					continue
				}

				absLogDir, err := filepath.Abs(dir)
				if err != nil {
					fmt.Printf("获取目录绝对路径失败: %v\n", err)
					continue
				}

				fmt.Printf("文件绝对路径: %s\n", absFilePath)
				fmt.Printf("目录绝对路径: %s\n", absLogDir)

				// 安全检查：确保文件路径在日志目录内
				if strings.HasPrefix(absFilePath, absLogDir) {
					fmt.Printf("路径验证成功: %s\n", absFilePath)
					return absFilePath, nil
				} else {
					fmt.Printf("路径安全检查失败: %s 不在目录 %s 内\n", absFilePath, absLogDir)
				}
			} else {
				fmt.Printf("文件不存在: %s, 错误: %v\n", fullPath, err)
			}
		}
		return "", fmt.Errorf("文件不存在或不在允许的目录内")
	}

	// 如果是绝对路径，验证是否在任一日志目录内
	absFilePath, err := filepath.Abs(cleanPath)
	if err != nil {
		return "", fmt.Errorf("文件路径格式错误")
	}

	for _, dir := range directories {
		absLogDir, err := filepath.Abs(dir)
		if err != nil {
			continue
		}

		// 安全检查：确保文件路径在日志目录内
		if strings.HasPrefix(absFilePath, absLogDir) {
			return absFilePath, nil
		}
	}

	return "", fmt.Errorf("文件路径不在允许的目录内")
}
