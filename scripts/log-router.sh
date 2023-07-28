#!/usr/bin/env bash

env=$1
clusterName="arbitrage-rest-api-cluster-$env"
services=$(aws ecs list-services --cluster=$clusterName --query="serviceArns[*]" --profile afriex --region eu-west-2 --output text)
s=($services)
for i in "${s[@]}"; do
    if [[ ${i} == *"arbitrage-rest-api-service"* ]]; then
        TASK_ARN=$(aws ecs list-tasks --cluster $clusterName --service-name $i --query 'taskArns[0]' --profile afriex --region eu-west-2 --output text)
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
echo "aws ecs execute-command --profile afriex --region eu-west-2 --cluster arbitrage-rest-api-cluster-$env --task $taskId --container log_router_$env --command \"/bin/sh\" --interactive"
 aws ecs execute-command --profile afriex --region eu-west-2 --cluster "arbitrage-rest-api-cluster-$env" --task "$taskId" --container "log_router_$env" --command "/bin/sh" --interactive
