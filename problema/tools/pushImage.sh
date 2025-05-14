#!/bin/bash
set -e

SERVICE_NAME="S3 SYNC"
DEFAULT_REPO="ghcr.io/bas-kirill"
DEFAULT_IMAGE_NAME="s3-sync"
DEFAULT_IMAGE_TAG="latest"

repo=$1
imageName=$2
imageTag=$3

if [ -z "$repo" ]; then
    echo -e "\033[0;33m[$SERVICE_NAME] No repo name provided. '$DEFAULT_REPO' will be used.\033[0m"
    repo="$DEFAULT_REPO"
fi

if [ -z "$imageName" ]; then
  echo -e "\033[0;33m[$SERVICE_NAME] No image name provided. '$DEFAULT_IMAGE_NAME' will be used.\033[0m"
  imageName="$DEFAULT_IMAGE_NAME"
fi

if [ -z "$imageTag" ]; then
  echo -e "\033[0;33m[$SERVICE_NAME] No image tag provided. '$DEFAULT_IMAGE_TAG' will be used.\033[0m"
  imageTag="$DEFAULT_IMAGE_TAG"
fi

imageFullName="$imageName:$imageTag"
repoImageFullName="$repo/$imageFullName"

(docker tag "$imageFullName" "$repoImageFullName")
(docker push "$repoImageFullName")
