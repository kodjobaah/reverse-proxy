[
  {
    "name": "${project}-${env}-reverse-proxy",
    "image": "${app_webhook_image}",
    "cpu": 1024,
    "memory": 2048,
    "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
    ],
    "environment": [ {
                    "name": "ENV",
                    "value": "${env}"
                }
    ],
    "mountPoints": [],
    "volumesFrom": [],
    "secrets": [],
    "logConfiguration": {
      "logDriver": "awslogs",
                    "options": {
                       "awslogs-group": "/ecs/webhook-reverse-proxy",
                       "awslogs-region": "${aws_region}",
                       "awslogs-create-group": "true",
                       "awslogs-stream-prefix": "webhhook"
                   }
    },
    "essential": true
  },
  {
   "name": "aws-otel-collector",
   "image": "amazon/aws-otel-collector",
   "portMappings": [
     {
       "hostPort": 2000,
       "protocol": "udp",
       "containerPort": 2000
     },
     {
       "hostPort": 4317,
       "protocol": "tcp",
       "containerPort": 4317
     },
     {
       "hostPort": 8125,
       "protocol": "udp",
       "containerPort": 8125
     }
   ],
   "essential": true,
   "logConfiguration": {
     "logDriver": "awslogs",
     "options": {
       "awslogs-group": "/ecs/webhook-reverse-proxy",
       "awslogs-region": "${aws_region}",
       "awslogs-stream-prefix": "aws-otel-collector",
       "awslogs-create-group": "True"
     }
   }
  }
]

fitness - integration: reduced usage
wiremock: - removed
binance webhook - reduced usage
wikijs - reduced resoruce usage

Outstanding: arbitrage bot



      const solid = new SolidWrapper();
      const data: WireRequest = {
        accountId: "acc-a9b98f53-fe55-4522-86c2-c805740146b0",
        contactId: "con-49ff3492-a647-47e6-8cac-22cdec7c7dc8",
        type: "international",
        amount: "100",
        description: 'swift FBLIGHAC test wire transfer from solid backed account'
      };
      const out  = await solid.wireTransfer(
        data,
        "per-fb0fc884-a9d2-4d4e-9ec4-7bed3358bf95",
      );
     console.log(out);