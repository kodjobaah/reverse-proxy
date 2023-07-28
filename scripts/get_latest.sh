#!/usr/bin/env bash

VERSIONS="$(aws ecr describe-images --region eu-west-2 --repository-name $1 --query 'sort_by(imageDetails,& imagePushedAt)[*].imageTags[*]' --output text | tr '\t' '\n' | grep -v 'latest' | tail -1)"
s=($VERSIONS)
echo $s
