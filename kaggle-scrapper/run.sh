#!/bin/bash
set -e
currentDir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

(cd "$currentDir" && docker build -t kaggle-scrapper .)
(docker tag kaggle-scrapper ghcr.io/bas-kirill/kaggle-scrapper:latest)
(docker push ghcr.io/bas-kirill/kaggle-scrapper:latest)
(cd "$currentDir" && docker compose down)
(cd "$currentDir" && docker compose up -d)
