#!/bin/bash
set -e
export HOME=/home/chronos
MD=http://metadata.google.internal/computeMetadata/v1/instance/attributes
attr() { curl -s -H "Metadata-Flavor: Google" "$MD/$1"; }

IMAGE=$(attr IMAGE)
ILB_IP=$(attr ILB_IP)

docker-credential-gcr configure-docker --registries=europe-west1-docker.pkg.dev
docker pull "$IMAGE"
docker rm -f web 2>/dev/null || true
docker run -d --name web --restart=always -p 80:8080 -e ILB_IP="$ILB_IP" "$IMAGE"
