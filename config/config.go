package config

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"

	"github.com/fsnotify/fsnotify"
	"github.com/spf13/viper"
)

// Config 配置结构体
type Config struct {
	Server ServerConfig `mapstructure:"server"`
	Auth   AuthConfig   `mapstructure:"auth"`
	Logs   LogsConfig   `mapstructure:"logs"`
}

// ServerConfig 服务器配置
type ServerConfig struct {
	Port string `mapstructure:"port"`
	Host string `mapstructure:"host"`
}

// AuthConfig 认证配置
type AuthConfig struct {
	Username string `mapstructure:"username"`
	Password string `mapstructure:"password"`
}

// LogsConfig 日志配置
type LogsConfig struct {
	Directories      []string `mapstructure:"directories"` // 支持多个日志目录
	Directory        string   `mapstructure:"directory"`   // 兼容旧版本，单个目录
	Pattern          string   `mapstructure:"pattern"`
	DefaultLines     int      `mapstructure:"default_lines"`
	MaxSearchResults int      `mapstructure:"max_search_results"`
}

var globalConfig *Config

// LoadConfig 加载配置文件
func LoadConfig() (*Config, error) {
	if globalConfig != nil {
		return globalConfig, nil
	}

	// 设置配置文件路径
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		return nil, fmt.Errorf("读取配置文件失败: %w", err)
	}

	// 解析配置
	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("解析配置文件失败: %w", err)
	}

	// 验证配置
	if err := validateConfig(&config); err != nil {
		return nil, fmt.Errorf("配置验证失败: %w", err)
	}

	// 添加调试信息
	fmt.Printf("配置加载成功:\n")
	fmt.Printf("  服务器: %s:%s\n", config.Server.Host, config.Server.Port)

	// 显示日志目录信息
	if len(config.Logs.Directories) > 0 {
		fmt.Printf("  日志目录: %v\n", config.Logs.Directories)
	} else if config.Logs.Directory != "" {
		fmt.Printf("  日志目录: %s\n", config.Logs.Directory)
	} else {
		fmt.Printf("  日志目录: ./logs (默认)\n")
	}

	fmt.Printf("  文件模式: %s\n", config.Logs.Pattern)
	fmt.Printf("  默认行数: %d\n", config.Logs.DefaultLines)

	// 监听配置文件变化
	viper.WatchConfig()
	viper.OnConfigChange(func(e fsnotify.Event) {
		fmt.Printf("配置文件已更改: %s\n", e.Name)
		// 重新加载配置
		if err := viper.ReadInConfig(); err == nil {
			if err := viper.Unmarshal(&config); err == nil {
				globalConfig = &config
				fmt.Println("配置已重新加载")
			}
		}
	})

	globalConfig = &config
	return globalConfig, nil
}

// GetConfig 获取全局配置
func GetConfig() *Config {
	return globalConfig
}

// validateConfig 验证配置
func validateConfig(config *Config) error {
	// 检查日志目录
	var directories []string
	if len(config.Logs.Directories) > 0 {
		directories = config.Logs.Directories
	} else if config.Logs.Directory != "" {
		directories = []string{config.Logs.Directory}
	} else {
		directories = []string{"./logs"}
	}

	// 验证所有目录
	for _, dir := range directories {
		if _, err := os.Stat(dir); os.IsNotExist(err) {
			// 如果是相对路径，尝试创建目录
			if !filepath.IsAbs(dir) {
				if err := os.MkdirAll(dir, 0755); err != nil {
					return fmt.Errorf("无法创建日志目录: %s, 错误: %w", dir, err)
				}
			} else {
				return fmt.Errorf("日志目录不存在: %s", dir)
			}
		}
	}

	// 检查端口格式
	if config.Server.Port == "" {
		config.Server.Port = "6003"
	}

	// 检查主机地址
	if config.Server.Host == "" {
		config.Server.Host = "0.0.0.0"
	}

	// 检查默认行数
	if config.Logs.DefaultLines <= 0 {
		config.Logs.DefaultLines = 200
	}

	// 检查最大搜索结果数
	if config.Logs.MaxSearchResults <= 0 {
		config.Logs.MaxSearchResults = 1000
	}

	return nil
}

// GetLogFiles 获取匹配的日志文件列表
func (c *Config) GetLogFiles() ([]string, error) {
	var files []string

	// 确定要扫描的目录列表
	var directories []string
	if len(c.Logs.Directories) > 0 {
		// 使用新的多目录配置
		directories = c.Logs.Directories
	} else if c.Logs.Directory != "" {
		// 兼容旧版本，使用单个目录
		directories = []string{c.Logs.Directory}
	} else {
		// 默认使用当前目录下的logs文件夹
		directories = []string{"./logs"}
	}

	fmt.Printf("开始扫描目录: %v\n", directories)
	fmt.Printf("使用模式: %s\n", c.Logs.Pattern)

	// 编译正则表达式
	pattern, err := regexp.Compile(c.Logs.Pattern)
	if err != nil {
		return nil, fmt.Errorf("正则表达式编译失败: %w", err)
	}

	// 遍历所有目录
	for _, dir := range directories {
		fmt.Printf("扫描目录: %s\n", dir)

		err = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				fmt.Printf("访问路径错误 %s: %v\n", path, err)
				return err
			}

			if !info.IsDir() {
				fmt.Printf("检查文件: %s (名称: %s)\n", path, info.Name())

				matched := pattern.MatchString(info.Name())
				fmt.Printf("文件 %s 匹配结果: %v\n", info.Name(), matched)

				if matched {
					files = append(files, path)
					fmt.Printf("添加文件: %s\n", path)
				}
			}

			return nil
		})

		if err != nil {
			fmt.Printf("扫描目录 %s 时出错: %v\n", dir, err)
			// 继续扫描其他目录，不中断
		}
	}

	fmt.Printf("扫描完成，找到 %d 个文件\n", len(files))
	return files, err
}
