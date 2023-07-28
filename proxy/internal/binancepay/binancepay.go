package binancepay

import (
	"crypto"
	"crypto/hmac"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/sha512"
	"crypto/x509"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io/ioutil"
	"net/http"
	"strconv"
	"strings"
	"time"

	log "github.com/sirupsen/logrus"

	"github.com/kodjobaah/afriex-webhook-proxy/proxy/internal/types"
)

type BinancePayClient struct {
	Client http.Client
}

func (bpc *BinancePayClient) GetPublicCert() (*types.BinancePayPublicCertResponse, error) {

	url := "https://bpay.binanceapi.com/binancepay/openapi/certificates"
	req, err := http.NewRequest("POST", url, nil)
	if err != nil {
		return nil, err
	}

	timestamp := strconv.FormatInt(time.Now().UTC().UnixMilli(), 10)
	nonce := make([]byte, 32)
	if _, err := rand.Read(nonce); err != nil {
		return nil, err
	}
	n := hex.EncodeToString(nonce)
	n = n[:32]

	h := hmac.New(sha512.New, []byte("kzv0kb1lxzvctn8vrpekmbwz1pisvnfwrurfppqyu8bsbihfgv0y9wqi6u01xdmd"))
	data := fmt.Sprintf("%s\n%s\n\n", timestamp, n)
	h.Write([]byte(data))

	sha := strings.ToUpper(hex.EncodeToString(h.Sum(nil)))
	req.Header = http.Header{
		"Content-Type":              []string{"application/json"},
		"BinancePay-Timestamp":      []string{timestamp},
		"BinancePay-Nonce":          []string{n},
		"BinancePay-Certificate-SN": []string{"q0r0bfc4mfav4rz7ycxkoq4o93gybmrgkfbtrvueppspcqef6focerfhrq6f6vfi"},
		"BinancePay-Signature":      []string{sha},
	}

	res, err := bpc.Client.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return nil, err
	}

	log.WithFields(
		log.Fields{
			"data": string(body),
		},
	).Info("BinancePayClient")
	var certResponse types.BinancePayPublicCertResponse
	err = json.Unmarshal(body, &certResponse)
	if err != nil {
		log.WithFields(
			log.Fields{
				"data": string(body),
			},
		).Info("BinancePayClient")
		return nil, err
	}
	return &certResponse, nil
}

func (bpc *BinancePayClient) VerifySignature(publicCert string, message string, rawSignature string) error {

	block, _ := pem.Decode([]byte(publicCert))
	x509Key, _ := x509.ParsePKIXPublicKey(block.Bytes)
	pubKey := x509Key.(*rsa.PublicKey)
	signature, err := base64.StdEncoding.DecodeString(rawSignature)
	if err != nil {
		return err
	}
	h := sha256.New()
	h.Write([]byte(message))
	digest := h.Sum(nil)
	err = rsa.VerifyPKCS1v15(pubKey, crypto.SHA256, digest, signature)
	if err != nil {
		return err
	}
	return nil
}
