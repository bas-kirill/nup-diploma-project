#!/bin/bash
set -e

case "$1" in
  awss3syncSmall)
    cd awss3syncSmall
    terraform destroy -auto-approve
    ;;
  awss3syncLarge)
    cd awss3syncLarge
    terraform destroy -auto-approve
    ;;
  awss3syncMaxFileCount)
    cd awss3syncMaxFileCount
    terraform destroy -auto-approve
    ;;
  awss3syncMaxDatasetSize)
    cd awss3syncMaxDatasetSize
    terraform destroy -auto-approve
    ;;
  rclonesyncSmall)
    cd rclonesyncSmall
    terraform destroy -auto-approve
    ;;
  rclonesyncLarge)
    cd rclonesyncLarge
    terraform destroy -auto-approve
    ;;
  rclonesyncMaxFileCount)
    cd rclonesyncMaxFileCount
    terraform destroy -auto-approve
    ;;
  rclonesyncMaxDatasetSize)
    cd rclonesyncMaxDatasetSize
    terraform destroy -auto-approve
    ;;
  s3cmdsyncSmall)
    cd s3cmdsyncSmall
    terraform destroy -auto-approve
    ;;
  s3cmdsyncLarge)
    cd s3cmdsyncLarge
    terraform destroy -auto-approve
    ;;
  s3cmdsyncMaxFileCount)
    cd s3cmdsyncMaxFileCount
    terraform destroy -auto-approve
    ;;
  s3cmdsyncMaxDatasetSize)
    cd s3cmdsyncMaxDatasetSize
    terraform destroy -auto-approve
    ;;
  s4cmdsyncSmall)
    cd s4cmdsyncSmall
    terraform destroy -auto-approve
    ;;
  s4cmdsyncLarge)
    cd s4cmdsyncLarge
    terraform destroy -auto-approve
    ;;
  s4cmdsyncMaxFileCount)
    cd s4cmdsyncMaxFileCount
    terraform destroy -auto-approve
    ;;
  s4cmdsyncMaxDatasetSize)
    cd s4cmdsyncMaxDatasetSize
    terraform destroy -auto-approve
    ;;
  mcmirrorSmall)
    cd mcmirrorSmall
    terraform destroy -auto-approve
    ;;
  mcmirrorLarge)
    cd mcmirrorLarge
    terraform destroy -auto-approve
    ;;
  mcmirrorMaxFileCount)
    cd mcmirrorMaxFileCount
    terraform destroy -auto-approve
    ;;
  mcmirrorMaxDatasetSize)
    cd mcmirrorMaxDatasetSize
    terraform destroy -auto-approve
    ;;
  *)
    echo "Usage: $0 {awss3syncSmall|awss3syncLarge|awss3syncMaxFileCount|awss3syncMaxDatasetSize|rclonesync|s3cmdsync|s4cmdsync|mcmirror}"
    exit 1
    ;;
esac
