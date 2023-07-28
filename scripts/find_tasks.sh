taskArns=$(aws ecs list-tasks --cluster arbitrage-rest-api-cluster-dev --query="taskArns[*]" --region eu-west-2  --output text)
 s=($taskArns)
 for i in "${s[@]}"
 do
 saveIFS=$IFS
 IFS="/"
 task_name=($i)
echo $task_name
 IFS=$saveIFS
 count=${#task_name[@]}
 task_name=${task_name[$count-1]}
echo $task_name
 done
