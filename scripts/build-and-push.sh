#!/usr/bin/env bash
set -euo pipefail
PROJECT="${PROJECT:?set PROJECT}"
REGION="${REGION:-europe-west1}"
TAG="${TAG:-1.0}"
REG="$REGION-docker.pkg.dev/$PROJECT/petclinic"

docker build --platform linux/amd64 -t "$REG/app:$TAG" app/
docker build --platform linux/amd64 -t "$REG/web:$TAG" web/
docker push "$REG/app:$TAG"
docker push "$REG/web:$TAG"
