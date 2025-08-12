package main

import (
	"log"
	"log-tools/config"
	"log-tools/handlers"
	"log-tools/middleware"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	// 加载配置
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	// 设置Gin模式
	gin.SetMode(gin.ReleaseMode)

	// 创建Gin引擎
	r := gin.Default()

	// 配置CORS
	r.Use(cors.Default())

	// 配置认证中间件
	r.Use(middleware.AuthMiddleware())

	// 静态文件服务
	r.Static("/static", "./static")
	r.LoadHTMLGlob("templates/*")

	// 路由组
	api := r.Group("/api")
	{
		// 认证相关
		api.POST("/login", handlers.Login)
		api.POST("/logout", handlers.Logout)
		api.GET("/check-auth", handlers.CheckAuth)

		// 日志相关（需要认证）
		logs := api.Group("/logs")
		logs.Use(middleware.AuthRequired())
		{
			logs.GET("/files", handlers.GetLogFiles)
			logs.GET("/content", handlers.GetLogContent)
			logs.POST("/search", handlers.SearchLogs)
		}
	}

	// 页面路由
	r.GET("/", handlers.IndexPage)
	r.GET("/login", handlers.LoginPage)
	r.GET("/test", func(c *gin.Context) {
		c.File("test-api.html")
	})

	// 启动服务器
	addr := cfg.Server.Host + ":" + cfg.Server.Port
	log.Printf("日志管理工具启动成功，访问地址: http://%s", addr)
	log.Fatal(r.Run(addr))
}
