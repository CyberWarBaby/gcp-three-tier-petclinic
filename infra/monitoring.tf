resource "google_service_account" "monitoring_sa" {
  account_id   = "${var.name_prefix}-monitoring-sa"
  display_name = "Monitoring SA"
}

resource "google_compute_firewall" "mon_to_app" {
  name        = "${var.name_prefix}-allow-mon-to-app"
  network     = google_compute_network.vpc_network.name
  direction   = "INGRESS"
  source_tags = ["monitoring"]
  target_tags = ["app"]

  allow {
    protocol = "tcp"
    ports    = ["9966", "9100"]
  }
}

resource "google_compute_firewall" "mon_to_web" {
  name        = "${var.name_prefix}-allow-mon-to-web"
  network     = google_compute_network.vpc_network.name
  direction   = "INGRESS"
  source_tags = ["monitoring"]
  target_tags = ["web"]

  allow {
    protocol = "tcp"
    ports    = ["9100"]
  }
}

resource "google_compute_firewall" "iap_to_mon" {
  name          = "${var.name_prefix}-allow-iap-to-mon"
  network       = google_compute_network.vpc_network.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["monitoring"]

  allow {
    protocol = "tcp"
    ports    = ["22", "3000", "9090"]
  }
}