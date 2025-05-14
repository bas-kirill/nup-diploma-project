#!/bin/bash

bucket="diploma-results"

if [ -z "$1" ]; then
  echo "Укажи тип синхронизации: awss3sync | rclonesync | s3cmdsync | s4cmdsync | mcmirror"
  exit 1
fi

sync_tool="$1"

case "$sync_tool" in
  awss3sync)
    pattern="awss3sync"
    ;;
  s3cmdsync)
    pattern="s3cmdsync"
    ;;
  s4cmdsync)
    pattern="s4cmdsync"
    ;;
  rclonesync)
    pattern="rclonesync"
    ;;
  mcmirror)
    pattern="mcmirror"
    ;;
  *)
    echo "Unknown sync tool: $sync_tool"
    echo "Valid options are: s3sync, s3cmd, s4cmd, rclonesync"
    exit 1
    ;;
esac

folder="./results/$pattern"
mkdir -p "$folder"

echo "Searching for objects containing '$pattern' in bucket '$bucket'..."
keys=$(aws s3api list-objects-v2 --bucket "$bucket" --query "Contents[].Key" --output text | tr '\t' '\n' | grep "$pattern")

if [ -z "$keys" ]; then
  echo "No matching objects found for pattern '$pattern'"
  exit 1
fi

echo "Downloading matching files..."
for key in $keys; do
  local_path="$folder/$key"
  mkdir -p "$(dirname "$local_path")"
  echo "Downloading: $key"
  aws s3 cp "s3://$bucket/$key" "$local_path"
done

echo "Download completed. Files saved in '$folder'"
