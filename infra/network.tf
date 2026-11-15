resource "google_compute_network" "vpc_network" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "web" {
  name                     = "${var.name_prefix}-web-subnet"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  ip_cidr_range            = "10.0.1.0/24"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "app" {
  name                     = "${var.name_prefix}-app-subnet"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  ip_cidr_range            = "10.0.2.0/24"
  private_ip_google_access = true
}

resource "google_compute_router" "router" {
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = google_compute_network.vpc_network.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.name_prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "lb_to_web" {
  name          = "${var.name_prefix}-allow-lb-to-web"
  network       = google_compute_network.vpc_network.name
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["web"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_firewall" "web_to_app" {
  name        = "${var.name_prefix}-allow-web-to-app"
  network     = google_compute_network.vpc_network.name
  direction   = "INGRESS"
  source_tags = ["web"]
  target_tags = ["app"]

  allow {
    protocol = "tcp"
    ports    = ["9966"]
  }
}

resource "google_compute_firewall" "hc_to_app" {
  name          = "${var.name_prefix}-allow-hc-to-app"
  network       = google_compute_network.vpc_network.name
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["app"]

  allow {
    protocol = "tcp"
    ports    = ["9966"]
  }
}

resource "google_compute_firewall" "iap_ssh" {
  name          = "${var.name_prefix}-allow-iap-ssh"
  network       = google_compute_network.vpc_network.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["web", "app"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}