#!/bin/bash

#!/usr/bin/env bash

env=$1
bastionHostKey="afriex-webhook-bastion-private-key-$1"
secrets=$(aws  secretsmanager list-secrets --region eu-west-2 --profile afriex --max-items 100 --query 'SecretList[*].ARN' --output text)
listOfSecrets=(${secrets// / })
for i in "${listOfSecrets[@]}"
do
    if [[ $i =~ $bastionHostKey ]];then
        rm -rf "webhook-bastion-$env.pem"
        aws secretsmanager get-secret-value --secret-id "$i" --profile afriex --region eu-west-2 --query 'SecretString' | tr -d '"' | base64 --decode > "fitnesse-bastion-$env.pem"
        chmod 0400 "fitnesse-bastion-$env.pem"
    fi
done

bastionHost=" aws --region eu-west-2  ec2 describe-instances --profile afriex  --region eu-west-2 | jq -r '.Reservations[].Instances[] | select(.SecurityGroups[] | .GroupName == \"webhook-proxy-dev-bastion\") | .NetworkInterfaces[].PrivateIpAddresses[].Association.PublicDnsName'"
c=$(eval $bastionHost)
echo "$c"
ssh -D 1080 -i "fitnesse-bastion-$env.pem" "ec2-user@$c"
