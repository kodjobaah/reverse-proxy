package types

type BinancePayPublicCert struct {
	CertPublic string `json:"certPublic"`
	CertSerail string `json:"certSerial"`
}
type BinancePayPublicCertResponse struct {
	Status string                 `json:"status"`
	Code   string                 `json:"code"`
	Data   []BinancePayPublicCert `json:"data"`
}

type BinanceResponse struct {
	BizType   string `json:"bizType"`
	Data      string `json:"data"`
	BizId     int64 `json:"bizId"`
	BizStatus string `json:"bizStatus"`
}

type BinanceResponseData struct {
	MerchantTradeNo string  `json:"merchantTradeNo"`
	TotalFee        string  `json:"totalFee"`
	TransactionTime string  `json:"transactTime"`
	Currency        float64 `json:"currency"`
	Commission      float64 `json:"commission"`
	ProductType     float64 `json:"productType"`
	ProductName     float64 `json:"productName"`
	TradeType       float64 `json:"tradeType"`
}

type WebhookProxy struct {
	Proxy           string
	Environment     string
	AdminServerUrl  string
	MongodbUrl      string
	MongoDbDatabase string
}

type WebhookProxyData struct {
	Proxy           string `json:"type"`
	Environment     string `json:"env"`
	AdminServerUrl  string `json:"serverUrl"`
	MongodbUrl      string `json:"mongodbUrl"`
	MongoDbDatabase string `json:"database"`
}
