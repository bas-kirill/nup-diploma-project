#!/bin/bash
set -e

./updateScripts.sh

case "$1" in
  awss3syncSmall)
    cd awss3syncSmall
    terraform apply -auto-approve
    ;;
  awss3syncLarge)
    cd awss3syncLarge
    terraform apply -auto-approve
    ;;
  awss3syncMaxFileCount)
    cd awss3syncMaxFileCount
    terraform apply -auto-approve
    ;;
  awss3syncMaxDatasetSize)
    cd awss3syncMaxDatasetSize
    terraform apply -auto-approve
    ;;
  rclonesyncSmall)
    cd rclonesyncSmall
    terraform apply -auto-approve
    ;;
  rclonesyncLarge)
    cd rclonesyncLarge
    terraform apply -auto-approve
    ;;
  rclonesyncMaxDatasetSize)
    cd rclonesyncMaxDatasetSize
    terraform apply -auto-approve
    ;;
  rclonesyncMaxFileCount)
    cd rclonesyncMaxFileCount
    terraform apply -auto-approve
    ;;
  s3cmdsyncSmall)
    cd s3cmdsyncSmall
    terraform apply -auto-approve
    ;;
  s3cmdsyncLarge)
    cd s3cmdsyncLarge
    terraform apply -auto-approve
    ;;
  s3cmdsyncMaxDatasetSize)
    cd s3cmdsyncMaxDatasetSize
    terraform apply -auto-approve
    ;;
  s3cmdsyncMaxFileCount)
    cd s3cmdsyncMaxFileCount
    terraform apply -auto-approve
    ;;
  s4cmdsyncSmall)
    cd s4cmdsyncSmall
    terraform apply -auto-approve
    ;;
  s4cmdsyncLarge)
    cd s4cmdsyncLarge
    terraform apply -auto-approve
    ;;
  s4cmdsyncMaxDatasetSize)
    cd s4cmdsyncMaxDatasetSize
    terraform apply -auto-approve
    ;;
  s4cmdsyncMaxFileCount)
    cd s4cmdsyncMaxFileCount
    terraform apply -auto-approve
    ;;
  mcmirrorSmall)
    cd mcmirrorSmall
    terraform apply -auto-approve
    ;;
  mcmirrorLarge)
    cd mcmirrorLarge
    terraform apply -auto-approve
    ;;
  mcmirrorMaxDatasetSize)
    cd mcmirrorMaxDatasetSize
    terraform apply -auto-approve
    ;;
  mcmirrorMaxFileCount)
    cd mcmirrorMaxFileCount
    terraform apply -auto-approve
    ;;
  *)
    echo "Usage: $0 {awss3syncSmall|rclonesync|s3cmdsync|s4cmdsync|mcmirror}"
    exit 1
    ;;
esac
