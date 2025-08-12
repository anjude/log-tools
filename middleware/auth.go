package middleware

import (
	"net/http"
	"strings"
	"sync"

	"github.com/gin-gonic/gin"
)

// 简单的内存存储认证
var (
	authenticatedUsers = make(map[string]bool)
	authMutex          sync.RWMutex
)

// AuthMiddleware 认证中间件
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 跳过登录页面、登录API和静态资源
		if c.Request.URL.Path == "/login" || c.Request.URL.Path == "/api/login" ||
			c.Request.URL.Path == "/static" || c.Request.URL.Path == "/" {
			c.Next()
			return
		}

		// 对于API请求，需要认证
		if strings.HasPrefix(c.Request.URL.Path, "/api/") {
			// 跳过登录API
			if c.Request.URL.Path == "/api/login" {
				c.Next()
				return
			}

			// 检查认证状态
			token := c.GetHeader("Authorization")
			if token == "" {
				token = c.Query("token")
			}

			if !isAuthenticated(token) {
				c.JSON(http.StatusUnauthorized, gin.H{
					"error": "未认证，请先登录",
				})
				c.Abort()
				return
			}
		}

		c.Next()
	}
}

// AuthRequired 认证中间件
func AuthRequired() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := c.GetHeader("Authorization")
		if token == "" {
			token = c.Query("token")
		}

		if !isAuthenticated(token) {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "未认证，请先登录",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// GetCurrentUser 获取当前用户ID
func GetCurrentUser(c *gin.Context) string {
	token := c.GetHeader("Authorization")
	if token == "" {
		token = c.Query("token")
	}

	if isAuthenticated(token) {
		return "milk" // 简化处理
	}
	return ""
}

// SetAuthenticated 设置用户认证状态
func SetAuthenticated(token string) {
	authMutex.Lock()
	defer authMutex.Unlock()
	authenticatedUsers[token] = true
}

// RemoveAuthenticated 移除用户认证状态
func RemoveAuthenticated(token string) {
	authMutex.Lock()
	defer authMutex.Unlock()
	delete(authenticatedUsers, token)
}

// isAuthenticated 检查是否已认证
func isAuthenticated(token string) bool {
	authMutex.RLock()
	defer authMutex.RUnlock()
	return authenticatedUsers[token]
}
