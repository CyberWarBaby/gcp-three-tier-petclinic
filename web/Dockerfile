# syntax=docker/dockerfile:1
ARG NODE_VERSION="24-alpine"
ARG NGINX_VERSION="1.27-alpine"

# Stage 1: build the Angular app
FROM node:${NODE_VERSION} AS build
WORKDIR /workspace
COPY package*.json ./
RUN npm config set fetch-retries 5 && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-timeout 600000
RUN --mount=type=cache,target=/root/.npm npm ci
COPY . .
RUN npm run build -- --configuration production
RUN set -e; \
    f=$(find dist -name index.html | head -n 1); \
    echo "Found: $f"; \
    mkdir -p /out; \
    cp -r "$(dirname "$f")"/. /out/

# Stage 2: serve with NGINX
FROM nginx:${NGINX_VERSION} AS runtime
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /out/ /usr/share/nginx/html/

RUN chown -R nginx:nginx /etc/nginx/conf.d /var/cache/nginx && \
    chmod a+rwx /var/run && \
    sed -i 's/^user/#user/' /etc/nginx/nginx.conf

ENV ILB_IP=10.0.0.10
EXPOSE 8080
USER nginx
HEALTHCHECK CMD wget -qO- http://127.0.0.1:8080/ >/dev/null || exit 1