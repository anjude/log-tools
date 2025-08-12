package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// IndexPage 主页面
func IndexPage(c *gin.Context) {
	c.HTML(http.StatusOK, "index.html", gin.H{
		"title": "日志管理工具",
	})
}

// LoginPage 登录页面
func LoginPage(c *gin.Context) {
	c.HTML(http.StatusOK, "login.html", gin.H{
		"title": "登录 - 日志管理工具",
	})
}
