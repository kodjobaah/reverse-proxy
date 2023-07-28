package main

import (
	"net/http"

	"github.com/gin-gonic/gin"

	log "github.com/sirupsen/logrus"

	"github.com/kodjobaah/afriex-webhook-proxy/proxy/internal/controller"
)

func main() {

	log.SetFormatter(&log.JSONFormatter{})
	log.SetReportCaller(true)

	router := gin.Default()

	var binance controller.Binance = controller.Binance{}
	var admin controller.Admin = controller.Admin{}

	router.GET("/status", func(ctx *gin.Context) {
		log.WithFields(
			log.Fields{
				"message": "status for proxy",
			},
		).Info("Proxy-Status")
		ctx.JSON(http.StatusOK, gin.H{
			"code":    http.StatusOK,
			"service": "proxy",
		})
	})

	router.POST("/webhook", binance.Process)
	router.POST("/admin", admin.Store)
	router.DELETE("/admin", admin.Delete)

	router.Run(":80")
}
