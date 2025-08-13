package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"github.com/anjude/log-tools/config"
	"github.com/anjude/log-tools/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
)

// LoginRequest 登录请求结构
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// Login 登录处理
func Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "请求参数错误",
		})
		return
	}

	cfg := config.GetConfig()
	if req.Username == cfg.Auth.Username && req.Password == cfg.Auth.Password {
		// 生成简单的token
		token := generateToken()
		middleware.SetAuthenticated(token)

		c.JSON(http.StatusOK, gin.H{
			"message": "登录成功",
			"user":    req.Username,
			"token":   token,
		})
	} else {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "用户名或密码错误",
		})
	}
}

// generateToken 生成简单的认证token
func generateToken() string {
	bytes := make([]byte, 16)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

// Logout 登出处理
func Logout(c *gin.Context) {
	token := c.GetHeader("Authorization")
	if token == "" {
		token = c.Query("token")
	}

	if token != "" {
		middleware.RemoveAuthenticated(token)
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "登出成功",
	})
}

// CheckAuth 检查认证状态
func CheckAuth(c *gin.Context) {
	token := c.GetHeader("Authorization")
	if token == "" {
		token = c.Query("token")
	}

	if middleware.GetCurrentUser(c) != "" {
		c.JSON(http.StatusOK, gin.H{
			"authenticated": true,
			"user":          "milk",
		})
		return
	}

	c.JSON(http.StatusUnauthorized, gin.H{
		"authenticated": false,
	})
}
