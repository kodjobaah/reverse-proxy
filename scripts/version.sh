#!/usr/bin/env bash

VERSION=$2
saveIFS=$IFS
IFS="/"
REPO=($1)
IFS=$saveIFS
count=${#REPO[@]}
REPO=${REPO[$count - 1]}
if [[ -z "$VERSION" ]]; then
 echo "latest"
else
    cmd="$(aws ecr describe-images --repository-name="$REPO" --image-ids=imageTag="$VERSION" 2> /dev/null )"
    if [[ -z "$cmd" ]]; then
        echo "$VERSION"
    else
        echo "latest"
    fi
fi
