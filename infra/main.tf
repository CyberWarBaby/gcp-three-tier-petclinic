terraform {
  backend "gcs" {
    bucket = "habeeb-tf-state"
    prefix = "terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_artifact_registry_repository" "docker_repo" {
  repository_id = "${var.name_prefix}-repo"
  description   = "${var.name_prefix} docker repository"
  location      = var.region
  format        = "DOCKER"
}

resource "google_service_account" "app_sa" {
  account_id   = "${var.name_prefix}-app-sa"
  display_name = "App Service-Account"
}

resource "google_service_account" "web_sa" {
  account_id   = "${var.name_prefix}-web-sa"
  display_name = "Web Service-Account"
}

resource "google_artifact_registry_repository_iam_member" "app_member" {
  project    = google_artifact_registry_repository.docker_repo.project
  location   = google_artifact_registry_repository.docker_repo.location
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.app_sa.email}"
}

resource "google_artifact_registry_repository_iam_member" "web_member" {
  project    = google_artifact_registry_repository.docker_repo.project
  location   = google_artifact_registry_repository.docker_repo.location
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.web_sa.email}"
}

resource "google_compute_global_address" "private_service_range" {
  name          = "${var.name_prefix}-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "psa" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]

  deletion_policy = "ABANDON"
}
