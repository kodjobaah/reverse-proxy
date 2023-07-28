#!/usr/bin/env bash

clusterName=$1
services=$(aws ecs list-services --cluster $clusterName --query="serviceArns[*]" --output text --profile weezy --region eu-west-2 )
s=($services)
for i in "${s[@]}"; do
    if [[ ${i} == *"weezy-marketplace-service"* ]]; then
        TASK_ARN=$(aws ecs list-tasks --cluster $clusterName --service-name $i --query 'taskArns[0]' --output text --profile weezy --region eu-west-2 )
        saveIFS=$IFS
        IFS="/"
        taskId=($TASK_ARN)
        IFS=$saveIFS
        count=${#taskId[@]}
        taskId=${taskId[$count - 1]}
       aws ecs stop-task --cluster "$clusterName" --task "$taskId" --profile weezy --region eu-west-2
    fi
    :
done
echo $taskId
