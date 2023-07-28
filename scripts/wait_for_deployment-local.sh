#!/usr/bin/env bash

clusterName=$1
oldTaskId=$(./scripts/get_task_id.sh $clusterName)
echo $oldTaskId
./scripts/redeploy-services.sh $clusterName
complete="no"
leaveLoop="no"
for ((c = 1; c <= 10; c++)); do
  newTaskId=$(./scripts/get_task_id.sh $clusterName)
  echo "newTaskId=$newTaskId oldTaskId=$oldTaskId"
  if [ "$newTaskId" != "None" ] && [ ! -z "$newTaskId" ]; then
    if [[ $oldTaskId != $newTaskId ]]; then
      leaveLoop="yes"
      for ((c = 1; c <= 10; c++)); do
        states=$(aws ecs describe-tasks --cluster $clusterName --tasks $newTaskId --query="tasks[*].containers[*].lastStatus" --region eu-west-2 --profile weezy --output text)
        echo "states=$states"
        statesArray=($states)
        output="found"
        for element in "${statesArray[@]}"; do
          if [ $element != "RUNNING" ]; then
            output="notfound"
            break
          fi
        done
        echo "this is output=$output"
        if [ $output = "found" ]; then
          complete="yes"
          break
        fi
        echo "waiting for task to get into running state"
        sleep 60
      done
    fi
  fi

  if [ $leaveLoop = "yes" ]; then
    break
  fi
  echo "waiting for task to change"
  sleep 60
done
echo "this is complete=$complete"
if [ $complete = "yes" ]; then
  cd jmeter
  mvn clean verify
else
  exit 1
fi
