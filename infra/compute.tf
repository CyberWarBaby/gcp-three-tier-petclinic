locals {
  image = "cos-cloud/cos-stable"
}

#APP TEMPLATE & MIG
resource "google_compute_instance_template" "app" {
  name_prefix  = "${var.name_prefix}-app-template-"
  machine_type = var.machine_type
  tags         = ["app"]

  disk {
    source_image = local.image
    auto_delete  = true
    boot         = true
    disk_size_gb = 10
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app.id
  }

  service_account {
    email  = google_service_account.app_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
    DB_HOST : google_sql_database_instance.db.private_ip_address
    DB_USER : var.db_user
    DB_PASSWORD : random_password.db.result
    IMAGE : "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.docker_repo.repository_id}/app:${var.image_tag}"
  }

  metadata_startup_script = file("${path.module}/../scripts/startup-app.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_health_check" "app" {
  name   = "${var.name_prefix}-app-hc"
  region = var.region

  http_health_check {
    port         = 9966
    request_path = "/petclinic/actuator/health"
  }
}

resource "google_compute_region_instance_group_manager" "app" {
  name               = "${var.name_prefix}-app-mig"
  base_instance_name = "${var.name_prefix}-app"
  region             = var.region
  target_size        = var.app_instance_count

  version {
    instance_template = google_compute_instance_template.app.self_link_unique
  }

  depends_on = [
    google_compute_router_nat.nat,
    google_sql_database.petclinic,
    google_sql_user.petclinic
  ]
  update_policy {
  type                  = "PROACTIVE"
  minimal_action        = "REPLACE"
  max_surge_fixed       = 3
  max_unavailable_fixed = 3
  }
}

resource "google_compute_region_backend_service" "app" {
  name                  = "${var.name_prefix}-app-backend"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.app.id]

  backend {
    group          = google_compute_region_instance_group_manager.app.instance_group
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_forwarding_rule" "app" {
  name                  = "${var.name_prefix}-app-ilb"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.app.id
  network               = google_compute_network.vpc_network.id
  subnetwork            = google_compute_subnetwork.app.id
  ip_protocol           = "TCP"
  ports                 = ["9966"]
}

#WEB TEMPLATE & MIG
resource "google_compute_instance_template" "web" {
  name_prefix  = "${var.name_prefix}-web-template-"
  machine_type = var.machine_type
  tags         = ["web"]

  disk {
    source_image = local.image
    auto_delete  = true
    boot         = true
    disk_size_gb = 10
  }

  network_interface {
    subnetwork = google_compute_subnetwork.web.id
  }

  service_account {
    email  = google_service_account.web_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
    ILB_IP         = google_compute_forwarding_rule.app.ip_address
    IMAGE          = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.docker_repo.repository_id}/app:${var.image_tag}"
  }

  metadata_startup_script = file("${path.module}/../scripts/startup-web.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "web" {
  name = "${var.name_prefix}-web-hc"

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_region_instance_group_manager" "web" {
  name               = "${var.name_prefix}-web-mig"
  region             = var.region
  base_instance_name = "${var.name_prefix}-web"
  target_size        = var.web_instance_count

  version {
    instance_template = google_compute_instance_template.web.self_link_unique
  }

  named_port {
    name = "http"
    port = 80
  }

  update_policy {
  type                  = "PROACTIVE"
  minimal_action        = "REPLACE"
  max_surge_fixed       = 3
  max_unavailable_fixed = 3
  }
  depends_on = [google_compute_router_nat.nat]
}

resource "google_compute_backend_service" "web" {
  name          = "${var.name_prefix}-web-backend"
  protocol      = "HTTP"
  port_name     = "http"
  timeout_sec   = 30
  health_checks = [google_compute_health_check.web.id]

  backend {
    group           = google_compute_region_instance_group_manager.web.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }
}

resource "google_compute_url_map" "web" {
  name            = "${var.name_prefix}-url-map"
  default_service = google_compute_backend_service.web.id
}

resource "google_compute_target_http_proxy" "web" {
  name    = "${var.name_prefix}-web-http-proxy"
  url_map = google_compute_url_map.web.id
}

resource "google_compute_global_address" "web" {
  name = "${var.name_prefix}-web-ip"
}

resource "google_compute_global_forwarding_rule" "web" {
  name       = "${var.name_prefix}-http-fr"
  target     = google_compute_target_http_proxy.web.id
  port_range = "80"
  ip_address = google_compute_global_address.web.id
}