#!/usr/bin/env bash

clusterName=$1
services=$(aws ecs list-services --cluster=$clusterName --region eu-west-2 --query="serviceArns[*]"  --output text)
s=($services)
for i in "${s[@]}"; do
    echo "$i"
    saveIFS=$IFS
    IFS="/"
    service_name=($i)
    IFS=$saveIFS
    count=${#service_name[@]}
    service_name=${service_name[$count - 1]}
    aws ecs update-service --cluster $clusterName --service "${service_name}" --region eu-west-2 --force-new-deployment

    :
done
