#!/bin/bash
set -e

docker-compose up -d --build

echo "🌐 MinIO Console: http://localhost:9001 (USERNAME / PASSWORD)"
