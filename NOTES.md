# Build notes: GCP three-tier Spring PetClinic (ClickOps phase)

Region europe-west1, zones -b and -c. Built by hand in the console and gcloud first, to be rebuilt in Terraform.

## Architecture
Browser -> global external LB (HTTP :80) -> web MIG (NGINX + Angular, container :8080 published on :80)
-> internal LB 10.0.2.10:9966 -> app MIG (Spring Boot REST, :9966) -> Cloud SQL PostgreSQL 16 (private IP, HA).
Each VM runs one container. Images live in Artifact Registry (petclinic repo). VMs have no external IPs.
Admin access is IAP SSH only. Outbound internet goes through Cloud NAT.

## Network design
| Item | Value |
|---|---|
| VPC | three-tier-vpc (custom mode, regional dynamic routing) |
| web-subnet | 10.0.1.0/24, Private Google Access on |
| app-subnet | 10.0.2.0/24, Private Google Access on |
| proxy-subnet | 10.0.100.0/24, purpose REGIONAL_MANAGED_PROXY (needed by the internal LB) |
| PSA range | google-managed-services-three-tier-vpc (reserved range peered to Google's service network) |
| Cloud NAT | three-tier-nat on three-tier-router, web and app subnets only |
| Internal LB IP | 10.0.2.10 (reserved static internal address) |

Firewall (all ingress, allow, priority 1000):
- allow-iap-ssh: tcp:22 from 35.235.240.0/20, tags web and app
- allow-lb-to-web: tcp:80 from 130.211.0.0/22 and 35.191.0.0/16, tag web
- allow-ilb-to-app: tcp:9966 from 10.0.100.0/24, tag app
- allow-healthcheck-app: tcp:9966 from 130.211.0.0/22 and 35.191.0.0/16, tag app

## Components
- App tier: template petclinic-app-template-v4 -> regional MIG petclinic-app-mig-v2 (2 VMs, zones -b and -c, named port app:9966) -> internal LB -> health check petclinic-app-hc (HTTP :9966, path /petclinic/api/pettypes, initial delay 300s)
- Web tier: template petclinic-web-template -> regional MIG petclinic-web-mig (2 VMs, named port http:80) -> global external LB -> health check petclinic-web-hc (global, HTTP :80, path /)
- Database: Cloud SQL petclinic-db, PostgreSQL 16, Enterprise, HA (primary europe-west1-b, standby europe-west1-c), private IP only (PSA), deletion protection off for the lab
- VM service account: petclinic-vm-sa with Artifact Registry Reader on the petclinic repo (Logs Writer optional)
- Images: web:1.0 and app:1.0, built with Docker and pushed to Artifact Registry
- Config is passed through instance metadata (IMAGE, DB_HOST, DB_USER, DB_PASSWORD, ILB_IP) and read by the startup scripts

## Problems hit and fixes
| Problem | Cause | Fix |
|---|---|---|
| Google denied the billing signup | Fraud filter on the card and billing profile, not a hack | Fixed the payments profile and signup details, stopped retrying the same card |
| apt-get: command not found | Machine runs Fedora 43 | Used dnf and the Google and HashiCorp rpm repos |
| New project missing in the console picker | Console shows the last-used project | Opened the direct dashboard URL with ?project= |
| gcloud: required property [project] not set | Default project not set | gcloud config set project <id> |
| allow-iap-ssh had one tag, webapp | Pressed no Enter between the tags web and app, so they merged | Edited the rule: two separate tag chips |
| Image pull failed: invalid reference format | Metadata key was lowercase image, script reads IMAGE. The key is case-sensitive, so the 404 page became the image name | Renamed the key to IMAGE. Script now checks for empty values |
| Backends unhealthy, app could not reach Cloud SQL | Template had TWO NICs. nic0 was on the default network, nic1 on three-tier-vpc. Traffic and the default route used nic0, and the PSA peering exists only on three-tier-vpc | New template with exactly one NIC, new MIG, swapped into the ILB backend service. In the console, edit the existing NIC, do not add one |
| MIG refused the new template | A MIG cannot change network interfaces ("Networks ... must be the same") | Created a new MIG instead of updating the old one |
| Cloud SQL rejected my generated password | Password policy needs upper, lower, digit and special characters, and a hex string has no uppercase or special characters | Generated a password with all four classes. The shell variable was also empty in a new terminal, so check variables before running |
| gcloud could not find a template with --region | Template was created global, since --region on create only sets the subnet's region | Describe and delete global templates without --region |
| gcloud could not parse resource [] | REGION and PROJECT unset in that terminal | Export variables in the same terminal as the commands |
| Password pasted into chat | Copied a console-generated command | Rotated the password. Never paste commands containing secrets |
| Build issues: npm timeouts, missing nginx template, backslashes from pasted text, wrong Angular dist folder | See HANDOFF.md | Retry settings, created the file, stripped backslashes, find-based copy of index.html |

## What I learned
- GCP VPCs are global and subnets are regional, so subnets span all zones. Zones only appear on VMs, MIGs and Cloud SQL.
- The ILB uses proxies from the proxy-only subnet, so app VMs see traffic from 10.0.100.0/24 and not from the web VMs.
- A VM's first NIC takes the default route, and load balancers and health checks target it.
- PSA is peering with Google's managed network. The app reaches Cloud SQL through it, and Cloud NAT has nothing to do with that path.
- Cloud SQL HA is one instance with a standby. Only the primary serves traffic, and failover keeps the same private IP.
- Metadata keys are case-sensitive. Startup scripts should fail loudly on missing values.
- Templates are immutable, and MIGs cannot change NICs. Fix by replacing, not editing.

## Verification checklist (tick before screenshots)
- [ ] 3 subnets, 4 firewall rules, NAT running
- [ ] Both app backends HEALTHY on petclinic-app-bes
- [ ] curl http://10.0.2.10:9966/petclinic/api/owners returns 200 from a VM
- [ ] Both web backends HEALTHY on petclinic-web-bes
- [ ] curl http://<LB_IP>/petclinic/api/owners returns 200
- [ ] Added an owner in the browser and it survived a reload
- [ ] Schema grant on Postgres 16 needed? (yes/no): ___
- [ ] Stopped one VM per tier and recorded recovery time: ___

## Cost notes
Cloud SQL HA, Cloud NAT, the two load balancers and 4 VMs all bill hourly. Tear down the same day. Deleting the project also deletes Artifact Registry images, so rebuild them with scripts/build-and-push.sh.

## What I would do differently
- Create templates with gcloud or Terraform, never the console form (the second-NIC trap).
- Add the metadata checks to the startup scripts from the start.
- Run the app image against local Postgres before touching the cloud.
- Keep a single terminal with exported variables, and confirm they are set.

## Next
Rebuild the same architecture in Terraform (infra/), starting flat with no modules, then split into modules, add CI/CD with Workload Identity Federation, run failure drills, and write it up.
