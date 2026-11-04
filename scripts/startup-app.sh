#!/bin/bash
set -e
export HOME=/home/chronos
MD=http://metadata.google.internal/computeMetadata/v1/instance/attributes
attr() { curl -s -H "Metadata-Flavor: Google" "$MD/$1"; }

IMAGE=$(attr IMAGE)
DB_HOST=$(attr DB_HOST)
DB_USER=$(attr DB_USER)
DB_PASSWORD=$(attr DB_PASSWORD)

docker-credential-gcr configure-docker --registries=europe-west1-docker.pkg.dev
docker pull "$IMAGE"
docker rm -f app 2>/dev/null || true
docker run -d --name app --restart=always -p 9966:9966 \
  -e SPRING_PROFILES_ACTIVE=postgres,spring-data-jpa \
  -e SPRING_DATASOURCE_URL="jdbc:postgresql://$DB_HOST:5432/petclinic" \
  -e SPRING_DATASOURCE_USERNAME="$DB_USER" \
  -e SPRING_DATASOURCE_PASSWORD="$DB_PASSWORD" \
  "$IMAGE"
