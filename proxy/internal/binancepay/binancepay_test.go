package binancepay

import (
	"crypto/sha256"
	"fmt"
	"testing"

	"github.com/hashicorp/go-retryablehttp"
	testdataloader "github.com/peteole/testdata-loader"
	"github.com/stretchr/testify/assert"
)

func TestGetPublicCert(t *testing.T) {
	retryClient := retryablehttp.NewClient()
	retryClient.RetryMax = 10
	c := retryClient.StandardClient()
	binancePayClient := BinancePayClient{*c}
	resp, err := binancePayClient.GetPublicCert()
	assert.Nil(t, err, "Should not have failed")
	assert.NotNil(t, resp.Data, "Should have returned the cert data")
	assert.NotNil(t, resp.Data[0].CertPublic, "Should have returned the public keu")

}

func TestValidateSignature(t *testing.T) {
	retryClient := retryablehttp.NewClient()
	retryClient.RetryMax = 10
	c := retryClient.StandardClient()
	binancePayClient := BinancePayClient{*c}
	resp, err := binancePayClient.GetPublicCert()
	if err != nil {
		assert.Fail(t, "Failed to get certificate", err)
	}
	body := testdataloader.GetTestFile("data/body.json")

	binancePayTimestamp := "1655295807836"
	binancePayNonce := "nxtVtm5x5hVy2be4600kAbci8sI2GNUMN"

	payload := fmt.Sprintf("%s\n%s\n%s\n", binancePayTimestamp, binancePayNonce, body)

	signature := testdataloader.GetTestFile("data/signature.txt")
	t.Logf("body[%s] signature[%s]", body, signature)
	hashed := sha256.Sum256([]byte(payload))
	err = binancePayClient.VerifySignature(resp.Data[0].CertPublic, string(hashed[:]), string(signature))
	t.Logf("err[%+v", err)
	assert.Equal(t, err.Error(), "crypto/rsa: verification error")
}
