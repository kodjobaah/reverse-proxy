#!/usr/bin/env bash

clusterName=$1
services=$(aws ecs list-services --cluster $clusterName --query="serviceArns[*]" --output text)
s=($services)
for i in "${s[@]}"; do
    if [[ ${i} == *"arbitrage-rest-api-service-dev"* ]]; then
        TASK_ARN=$(aws ecs list-tasks --cluster $clusterName --service-name $i --query 'taskArns[0]' --output text)
        saveIFS=$IFS
        IFS="/"
        taskId=($TASK_ARN)
        IFS=$saveIFS
        count=${#taskId[@]}
        taskId=${taskId[$count - 1]}
    fi
    :
done
echo $taskId
