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
	Directory        string `mapstructure:"directory"`
	Pattern          string `mapstructure:"pattern"`
	DefaultLines     int    `mapstructure:"default_lines"`
	MaxSearchResults int    `mapstructure:"max_search_results"`
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
	fmt.Printf("  日志目录: %s\n", config.Logs.Directory)
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
	// 检查日志目录是否存在
	if _, err := os.Stat(config.Logs.Directory); os.IsNotExist(err) {
		// 如果是相对路径，尝试创建目录
		if !filepath.IsAbs(config.Logs.Directory) {
			if err := os.MkdirAll(config.Logs.Directory, 0755); err != nil {
				return fmt.Errorf("无法创建日志目录: %s, 错误: %w", config.Logs.Directory, err)
			}
		} else {
			return fmt.Errorf("日志目录不存在: %s", config.Logs.Directory)
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

	fmt.Printf("开始扫描目录: %s\n", c.Logs.Directory)
	fmt.Printf("使用模式: %s\n", c.Logs.Pattern)

	// 编译正则表达式
	pattern, err := regexp.Compile(c.Logs.Pattern)
	if err != nil {
		return nil, fmt.Errorf("正则表达式编译失败: %w", err)
	}

	err = filepath.Walk(c.Logs.Directory, func(path string, info os.FileInfo, err error) error {
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

	fmt.Printf("扫描完成，找到 %d 个文件\n", len(files))
	return files, err
}
