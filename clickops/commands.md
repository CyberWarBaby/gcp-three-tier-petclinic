# gcloud equivalents of the console steps

Project: three-tier-lab-habeeb01, region: europe-west1

## 1. VPC and subnets

```bash
gcloud compute networks create three-tier-vpc --project=three-tier-lab-habeeb01 --description="three-tier-vpc clickops" --subnet-mode=custom --bgp-routing-mode=regional --bgp-best-path-selection-mode=legacy

gcloud compute networks subnets create web-subnet --project=three-tier-lab-habeeb01 --range=10.0.1.0/24 --stack-type=IPV4_ONLY --network=three-tier-vpc --region=europe-west1 --enable-private-ip-google-access

gcloud compute networks subnets create app-subnet --project=three-tier-lab-habeeb01 --range=10.0.2.0/24 --stack-type=IPV4_ONLY --network=three-tier-vpc --region=europe-west1 --enable-private-ip-google-access

# proxy-only subnet for the internal Application Load Balancer
gcloud compute networks subnets create proxy-only-subnet --project=three-tier-lab-habeeb01 --range=10.0.100.0/24 --network=three-tier-vpc --region=europe-west1 --purpose=REGIONAL_MANAGED_PROXY --role=ACTIVE
```

## 2. Firewall rules

```bash
# SSH only through IAP
gcloud compute firewall-rules create allow-iap-ssh --project=three-tier-lab-habeeb01 --direction=INGRESS --priority=1000 --network=three-tier-vpc --action=ALLOW --rules=tcp:22 --source-ranges=35.235.240.0/20 --target-tags=web,app

# external LB and health checks to web tier
gcloud compute firewall-rules create allow-lb-to-web --project=three-tier-lab-habeeb01 --direction=INGRESS --priority=1000 --network=three-tier-vpc --action=ALLOW --rules=tcp:80 --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=web

# internal LB proxies to app tier
gcloud compute firewall-rules create allow-ilb-to-app --project=three-tier-lab-habeeb01 --direction=INGRESS --priority=1000 --network=three-tier-vpc --action=ALLOW --rules=tcp:9966 --source-ranges=10.0.100.0/24 --target-tags=app

# health checks to app tier
gcloud compute firewall-rules create allow-healthcheck-app --project=three-tier-lab-habeeb01 --direction=INGRESS --priority=1000 --network=three-tier-vpc --action=ALLOW --rules=tcp:9966 --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=app
```
