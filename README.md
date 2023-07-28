# afriex-webhook-proxy

> Proxy used to handle webhook calls and forward the request to the appropriate server
- [afriex-webhook-proxy](#afriex-webhook-proxy)
  - [Setup for local development](#setup-for-local-development)


## Setup for local development

`~/.ngrok2/ngrok.yml`
modify so that content looks like the following:
```
authtoken: xxxxxxxxxxx
tunnels:
  admin:
     addr: 3030
     proto: http
  mongodb:
     addr: 27017
     proto: tcp
```
Then run the command `ngrok start --all`
You should see the following:
```
Session Status                online
Account                       Kodjo Baah (Plan: Free)
Version                       2.3.40
Region                        United States (us)
Web Interface                 http://127.0.0.1:4040
Forwarding                    http://5110-84-70-185-123.ngrok.io -> http://localhost:3030
Forwarding                    https://5110-84-70-185-123.ngrok.io -> http://localhost:3030
Forwarding                    tcp://8.tcp.ngrok.io:13710 -> localhost:27017
Connections                   ttl     opn     rt1     rt5     p50     p90
                              2       0       0.00    0.00    1.90    1.96
```
Then create a json file .ie. `webhook-proxy.json` using the data from up above

e.g
```
{
  "type": "Binance",
  "env": "mika",
  "serverUrl": "https://5110-84-70-185-123.ngrok.io/binance/webhook",
  "mongodbUrl": "mongodb://8.tcp.ngrok.io:13710/?readPreference=primary&appname=MongoDB%20Compass&directConnection=true&ssl=false",
  "database": "afriex_development"
}
```

`curl -X POST -H "Content-Type: application/json" -d @./webhook-proxy.json http://webhook.afreixdev.com/proxy`

To delete using the same json file but instead:

`curl -X DELETE -H "Content-Type: application/json" -d @./webhook-proxy.json http://webook.afreixdev.com/proxy`


### GOTACHS

?   	github.com/kodjobaah/afriex-webhook-proxy/proxy/cmd/proxy	[no test files]
--- FAIL: TestGetPublicCert (1.00s)
    binancepay_test.go:15: Say bye <nil>
    binancepay_test.go:16:
        	Error Trace:	binancepay_test.go:16
        	Error:      	Expected nil, but got: &url.Error{Op:"Post", URL:"https://bpay.binanceapi.com/binancepay/openapi/certificates", Err:(*http.httpError)(0x1400028c048)}
        	Test:       	TestGetPublicCert
        	Messages:   	Should not have failed
panic: runtime error: invalid memory address or nil pointer dereference [recovered]
	panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x2 addr=0x20 pc=0x10104b6e4]

goroutine 19 [running]:
testing.tRunner.func1.2({0x101103b60, 0x1012e3a30})
	/opt/homebrew/Cellar/go/1.18/libexec/src/testing/testing.go:1389 +0x1c8
testing.tRunner.func1()
	/opt/homebrew/Cellar/go/1.18/libexec/src/testing/testing.go:1392 +0x384
panic({0x101103b60, 0x1012e3a30})
	/opt/homebrew/Cellar/go/1.18/libexec/src/runtime/panic.go:838 +0x204
github.com/kodjobaah/afriex-webhook-proxy/proxy/internal/binancepay.TestGetPublicCert(0x14000105a00)
	/Users/kodjo/workspace/afriex/afriex-webhook-proxy/proxy/internal/binancepay/binancepay_test.go:17 +0x174
testing.tRunner(0x14000105a00, 0x10114aff0)
	/opt/homebrew/Cellar/go/1.18/libexec/src/testing/testing.go:1439 +0x110
created by testing.(*T).Run
