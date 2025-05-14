#!/bin/bash
set -e
currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
rootDir="$currentDir/../"

SERVICE_NAME="S3 SYNC"
DEFAULT_IMAGE_NAME="s3-sync"
DEFAULT_IMAGE_TAG="latest"

imageName=$1
imageTag=$2

if [ -z "$imageName" ]; then
  echo -e "\033[0;33m[$SERVICE_NAME] No service name provided. '$DEFAULT_IMAGE_NAME' will be used.\033[0m"
  imageName="$DEFAULT_IMAGE_NAME"
fi

if [ -z "$imageTag" ]; then
  echo -e "\033[0;33m[$SERVICE_NAME] No image tag provided. '$DEFAULT_IMAGE_TAG' will be used.\033[0m"
  imageTag="$DEFAULT_IMAGE_TAG"
fi

imageFullName="$imageName:$imageTag"

echo "[$SERVICE_NAME] Building '$imageFullName'..."

# Check if the image exists before attempting to remove it
if docker images -q "$imageFullName" &> /dev/null; then
  docker rmi -f "$imageFullName"
  echo "[$SERVICE_NAME] old image '$imageFullName' removed"
fi

echo "[$SERVICE_NAME] building '$imageFullName'..."
(DOCKER_BUILDKIT=1 docker buildx build  \
  -f "${rootDir}/Dockerfile" \
  -t "$imageFullName" \
  "$rootDir")

echo -e "\033[0;32m[$SERVICE_NAME FINISHED] image '$imageFullName' has been built\033[0m"
