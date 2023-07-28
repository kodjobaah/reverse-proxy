#!/usr/bin/env bash

clusterName=$1
services=$(aws ecs list-services --cluster=$clusterName --query="serviceArns[*]" --output text --profile afriex  --region eu-west-2)
s=($services)
for i in "${s[@]}"; do
    echo "$i"
    saveIFS=$IFS
    IFS="/"
    service_name=($i)
    IFS=$saveIFS
    count=${#service_name[@]}
    service_name=${service_name[$count - 1]}
    aws ecs update-service --cluster $clusterName --service "${service_name}" --force-new-deployment --profile afriex  --region eu-west-2
    :
done
