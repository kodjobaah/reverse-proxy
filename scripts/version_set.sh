#!/usr/bin/env bash

VERSION_TO_PUSH=$2
saveIFS=$IFS
IFS="/"
REPO=($1)
IFS=$saveIFS
count=${#REPO[@]}
REPO=${REPO[$count - 1]}
if [[ -z "$VERSION_TO_PUSH" ]]; then
 VERSION_TO_PUSH=""
else
    cmd="$(aws ecr describe-images --repository-name="$REPO" --image-ids=imageTag="$VERSION_TO_PUSH" 2> /dev/null )"
    if [[ -n "$cmd" ]]; then
        VERSION_TO_PUSH=""
    fi
fi

if [[ -n "${VERSION_TO_PUSH}" ]]; then
    docker push "$REPOSITORY_FLUENTBIT_URI":"$VERSION_TO_PUSH"
    docker push "$REPOSITORY_WEBHOOK_URI":"$VERSION_TO_PUSH"
fi
