resource "random_id" "db_suffix" {
  byte_length = 3
}

resource "random_password" "db" {
  length  = 20
  special = false
}

resource "google_sql_database_instance" "db" {
  name                = "${var.name_prefix}-db-${random_id.db_suffix.hex}"
  region              = var.region
  database_version    = "POSTGRES_15"
  deletion_protection = false #  set true for anything real

  settings {
    tier      = "db-f1-micro"
    edition   = "ENTERPRISE"
    disk_size = 10

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.id
    }
  }

  depends_on = [google_service_networking_connection.psa]
}

resource "google_sql_database" "petclinic" {
  name     = var.db_name
  instance = google_sql_database_instance.db.name
}

resource "google_sql_user" "petclinic" {
  name     = var.db_user
  instance = google_sql_database_instance.db.name
  password = random_password.db.result
}