package controller

import (
	"net/http"

	"context"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	awstypes "github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/gin-gonic/gin"
	"github.com/kodjobaah/afriex-webhook-proxy/proxy/internal/types"
)

const TableNameAdmin = "WebhookProxy"
const RegionAdmin = "eu-west-2"

type Admin struct{}

func (p *Admin) Delete(c *gin.Context) {

	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	svc := dynamodb.NewFromConfig(cfg, func(o *dynamodb.Options) {
		o.Region = RegionAdmin
	})

	var webhookProxyData types.WebhookProxyData
	if err := c.BindJSON(&webhookProxyData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	input, err := svc.DeleteItem(context.TODO(), &dynamodb.DeleteItemInput{
		TableName: aws.String(TableNameAdmin),
		Key: map[string]awstypes.AttributeValue{
			"Proxy":       &awstypes.AttributeValueMemberS{Value: webhookProxyData.Proxy},
			"Environment": &awstypes.AttributeValueMemberS{Value: webhookProxyData.Environment},
		},
	})
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusAccepted, gin.H{"deleted": input.Attributes})
}

func (p *Admin) Store(c *gin.Context) {

	var webhookProxyData types.WebhookProxyData
	if err := c.BindJSON(&webhookProxyData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"errorBinding": err.Error()})
		return
	}

	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	svc := dynamodb.NewFromConfig(cfg, func(o *dynamodb.Options) {
		o.Region = RegionAdmin
	})

	webhookProxy := types.WebhookProxy(webhookProxyData)
	item, err := attributevalue.MarshalMap(webhookProxy)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"errorPutItem": err.Error()})
	}

	input, err := svc.PutItem(c.Request.Context(), &dynamodb.PutItemInput{
		Item:      item,
		TableName: aws.String(TableNameAdmin),
	})
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"errorPutItem": err.Error()})
	}
	c.JSON(http.StatusAccepted, gin.H{"stored": input.Attributes})
}
