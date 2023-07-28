package controller

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strconv"
	"strings"
	"time"

	log "github.com/sirupsen/logrus"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/gin-gonic/gin"
	"github.com/kodjobaah/afriex-webhook-proxy/proxy/internal/binancepay"
	"github.com/kodjobaah/afriex-webhook-proxy/proxy/internal/types"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Binance struct {
	context *gin.Context
}

const TableName = "WebhookProxy"
const Region = "eu-west-2"

func (p *Binance) fetchProxyDetails(c *gin.Context) []types.WebhookProxy {

	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return nil
	}

	svc := dynamodb.NewFromConfig(cfg)

	// Create the Expression to fill the input struct with.
	filt := expression.Name("Proxy").Equal(expression.Value("Binance"))

	expr, err := expression.NewBuilder().WithFilter(filt).Build()

	if err != nil {
		log.WithFields(
			log.Fields{
				"message": fmt.Sprintf("%s", err),
			},
		).Error("DynamoDB")
		return nil
	}

	// Build the query input parameters
	params := &dynamodb.ScanInput{
		ExpressionAttributeNames:  expr.Names(),
		ExpressionAttributeValues: expr.Values(),
		FilterExpression:          expr.Filter(),
		ProjectionExpression:      expr.Projection(),
		TableName:                 aws.String(TableName),
	}

	// Make the DynamoDB Query API call
	result, err := svc.Scan(context.TODO(), params)

	if err != nil {
		log.WithFields(
			log.Fields{
				"message": fmt.Sprintf("%s", err),
			},
		).Error("DynamoDB")
	}

	proxyData := []types.WebhookProxy{}
	err = attributevalue.UnmarshalListOfMaps(result.Items, &proxyData)
	if err != nil {
		log.Error(err)
	}

	return proxyData
}

func (p *Binance) checkAndForward(ctx *gin.Context, proxyData types.WebhookProxy, binanceResponse types.BinanceResponse, process chan bool) bool {

	// Used to return the response incase of an error
	p.context = ctx

	log.WithFields(
		log.Fields{
			"Proxy":           proxyData.Proxy,
			"Environment":     proxyData.Environment,
			"AdminServerUrl":  proxyData.AdminServerUrl,
			"MongodbUrl":      proxyData.MongodbUrl,
			"MongoDbDatabase": proxyData.MongoDbDatabase,
			"BizId":           binanceResponse.BizId,
		},
	).Info("MongoDb")

	opts := options.Client()
	opts.ApplyURI(proxyData.MongodbUrl)

	opts.SetConnectTimeout(1 * time.Second)
	mongoCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	client, err := mongo.Connect(context.TODO(), opts)
	if err != nil {
		log.WithFields(
			log.Fields{
				"message": fmt.Sprintf("%s", err),
				"env":     proxyData.Environment,
			},
		).Error("MongoDb")
		process <- false
		return false
	}
	coll := client.Database(proxyData.MongoDbDatabase).Collection("binanceorders")
	var result bson.M

	filter := bson.D{primitive.E{Key: "paymentId", Value: strconv.FormatInt(binanceResponse.BizId, 10)}}
	err = coll.FindOne(mongoCtx, filter).Decode(&result)
	if err == mongo.ErrNoDocuments {
		log.WithFields(
			log.Fields{
				"message": fmt.Sprintf("%s", err),
				"env":     proxyData.Environment,
			},
		).Error("MongoDb")
		process <- false
		return false
	}
	if err != nil {
		log.WithFields(
			log.Fields{
				"message": fmt.Sprintf("%s", err),
			},
		).Error("MongoDb")
		process <- false
		return false
	}
	_, err = json.MarshalIndent(result, "", "    ")
	if err != nil {
		log.WithFields(
			log.Fields{
				"message": fmt.Sprintf("%s", err),
			},
		).Error("MongodDB")
		process <- false
		return false
	}

	remote, err := url.Parse(proxyData.AdminServerUrl)
	if err != nil {
		log.WithFields(
			log.Fields{
				"message": fmt.Sprintf("%s", err),
				"env":     proxyData.AdminServerUrl,
			},
		).Error("ForwardRequest")
		process <- false
		return false
	}
	proxy := httputil.NewSingleHostReverseProxy(remote)
	proxy.Director = func(req *http.Request) {
		req.Header.Set("X-Forwarded-Host", req.Header.Get("Host"))
		//req.Header.Set("X-Forwarded-Proto", req.Header.Get("https"))

		req.Header = ctx.Request.Header
		req.Host = remote.Host
		req.URL.Scheme = remote.Scheme
		req.URL.Host = remote.Host
		req.URL.Path = "/binance/webhook"
	}
	proxy.Transport = &http.Transport{
		Proxy: func(req *http.Request) (*url.URL, error) {
			host, err := http.ProxyFromEnvironment(req)
			return host, err
		},
		Dial: func(network, addr string) (net.Conn, error) {
			conn, err := (&net.Dialer{
				Timeout:   30 * time.Second,
				KeepAlive: 0,
			}).Dial(network, addr)
			if err != nil {
				log.WithFields(
					log.Fields{
						"message": fmt.Sprintf("%s", err),
					},
				).Error("ForwardRequest")
			}
			return conn, err
		},
		TLSHandshakeTimeout: 30 * time.Second,
	}

	proxy.ErrorHandler = p.ErrHandle
	proxy.ModifyResponse = p.ModifyResponse
	//ctx.Request.URL.Host = remote.Host
	//ctx.Request.URL.Scheme = remote.Scheme
	//ctx.Request.Header.Set("X-Forwarded-Host", ctx.Request.Header.Get("Host"))
	//ctx.Request.Host = remote.Host
	proxy.ServeHTTP(ctx.Writer, ctx.Request)
	process <- true
	log.WithFields(
		log.Fields{
			"message": "Forward Request",
			"env":     proxyData.AdminServerUrl,
		},
	).Info("ForwardRequest")
	return true
}

func (p *Binance) ModifyResponse(res *http.Response) error {
	if res.StatusCode == 404 {
		return errors.New("404 error from the host")
	}
	return nil
}

func (p *Binance) waitForItems(process chan bool, numProxies int) bool {
	count := 0
	for {
		select {
		case processed := <-process:
			if !processed {
				return false
			}
			count = count + 1
			if count == numProxies {
				return true
			}
		}
	}
}

func (p *Binance) ErrHandle(res http.ResponseWriter, req *http.Request, err error) {
	p.context.JSON(http.StatusBadRequest, gin.H{
		"returnCode":    "FAIL",
		"returnMessage": "Unable to connect to endpoint"})
}

func (p *Binance) validateRequest(ctx *gin.Context, body string, signature string) bool {

	retryClient := retryablehttp.NewClient()
	retryClient.RetryMax = 10
	c := retryClient.StandardClient()
	binancePayClient := binancepay.BinancePayClient{Client: *c}
	resp, err := binancePayClient.GetPublicCert()
	if err == nil {
		err := binancePayClient.VerifySignature(resp.Data[0].CertPublic, body, signature)
		if err != nil {
			log.WithFields(
				log.Fields{
					"data":       string(body),
					"error":      err.Error(),
					"signature":  signature,
					"publicCert": resp.Data[0].CertPublic,
				},
			).Error("Validator")

			ctx.JSON(http.StatusBadRequest, gin.H{
				"returnCode":    "FAIL",
				"returnMessage": "failed Signature Verificationt"})
			return false
		}
	}
	return true
}

func (p *Binance) Process(ctx *gin.Context) {
	body, err := ioutil.ReadAll(ctx.Request.Body)
	payload := fmt.Sprintf("%s\n%s\n%s\n", ctx.GetHeader("Binancepay-Timestamp"), ctx.GetHeader("Binancepay-Nonce"), body)
	signature := ctx.GetHeader("Binancepay-Signature")
	if signature != "" &&
		!p.validateRequest(ctx, payload, signature) {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"returnCode":    "FAIL",
			"returnMessage": "unable to validate request"})
		return
	}

	rdr := ioutil.NopCloser(bytes.NewBuffer(body))
	if err != nil {
		log.WithFields(
			log.Fields{
				"message": fmt.Sprintf("%s", err),
			},
		).Error("Validator")
		ctx.JSON(http.StatusBadRequest, gin.H{
			"returnCode":    "FAIL",
			"returnMessage": err.Error()})
		return
	}

	var binanceResponse types.BinanceResponse
	var binanceResponseData types.BinanceResponseData
	b, err := ioutil.ReadAll(rdr)
	if err != nil {
		log.WithFields(
			log.Fields{
				"message": fmt.Sprintf("%s", err),
			},
		).Error("Proxy")
		ctx.JSON(http.StatusBadRequest, gin.H{
			"returnCode":    "FAIL",
			"returnMessage": err.Error()})
		return
	}

	err = json.Unmarshal(b, &binanceResponse)
	if err != nil {
		log.WithFields(
			log.Fields{
				"message": fmt.Sprintf("%s", err),
			},
		).Error("Proxy")
		ctx.JSON(http.StatusBadRequest, gin.H{
			"returnCode":    "FAIL",
			"returnMessage": err.Error()})
		return
	}

	json.Unmarshal([]byte(binanceResponse.Data), &binanceResponseData)

	processed := make(chan bool)
	proxyDetails := p.fetchProxyDetails(ctx)
	ctx.Request.Body = rdr
	count := 0
	for _, pd := range proxyDetails {
		if strings.TrimSpace(pd.AdminServerUrl) != "" &&
			strings.TrimSpace(pd.MongodbUrl) != "" {
			go p.checkAndForward(ctx, pd, binanceResponse, processed)
			count++
		}
	}

	if !p.waitForItems(processed, count) {
		log.WithFields(
			log.Fields{
				"message": "Nothing was processed",
			},
		).Error("Proxy")
		ctx.JSON(http.StatusBadRequest, gin.H{
			"returnCode":    "FAIL",
			"returnMessage": "The order does not exist"})

	}

}
