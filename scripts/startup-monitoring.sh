#!/bin/bash
set -e
export HOME=/home/chronos
MD=http://metadata.google.internal/computeMetadata/v1/instance/attributes

mkdir -p /var/prometheus
curl -sf -H "Metadata-Flavor: Google" "$MD/PROM_CONFIG" > /var/prometheus/prometheus.yml
[ -s /var/prometheus/prometheus.yml ] || { echo "missing metadata: PROM_CONFIG" >&2; exit 1; }

iptables -w -A INPUT -p tcp -m multiport --dports 3000,9090 -j ACCEPT
docker rm -f prometheus 2>/dev/null || true
docker run -d --name prometheus --restart=always --net=host \
  -v /var/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
  prom/prometheus

docker rm -f grafana 2>/dev/null || true
docker run -d --name grafana --restart=always --net=host \
  grafana/grafana-oss