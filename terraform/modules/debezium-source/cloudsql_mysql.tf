# Random password for the datastream user
resource "random_password" "ds_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "root_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "admin_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

# Cloud SQL for MySQL instance
resource "google_sql_database_instance" "mysql_instance" {
  name             = var.db_instance_name
  database_version = var.db_version
  region           = var.region
  depends_on = [
    var.enabled_apis,
    var.private_service_connection_network
  ]

  settings {
    tier = var.db_tier
    backup_configuration {
      enabled            = true
      binary_log_enabled = true
    }
    ip_configuration {
      ipv4_enabled    = true
      private_network = var.vpc_id
      psc_config {
        psc_enabled               = true
        allowed_consumer_projects = var.allowed_psc_projects
      }
    }
    database_flags {
      name  = "binlog_row_image"
      value = "full"
    }
    database_flags {
      name  = "max_allowed_packet"
      value = "1073741824" # 1GB
    }
    database_flags {
      name  = "net_read_timeout"
      value = "3600"
    }
    database_flags {
      name  = "net_write_timeout"
      value = "3600"
    }
    database_flags {
      name  = "wait_timeout"
      value = "86400"
    }
    availability_type = "ZONAL"
    disk_autoresize   = true
    disk_size         = 20
  }
  deletion_protection = false
}

# SQL User for Datastream
resource "google_sql_user" "datastream_user" {
  name     = "datastream"
  host     = "%"
  instance = google_sql_database_instance.mysql_instance.name
  password = random_password.ds_password.result
}

resource "google_sql_user" "root_user" {
  name     = "root"
  host     = "%"
  instance = google_sql_database_instance.mysql_instance.name
  password = random_password.root_password.result
}

resource "google_sql_user" "admin_user" {
  name     = "rdsadmin"
  host     = "%"
  instance = google_sql_database_instance.mysql_instance.name
  password = random_password.admin_password.result
}

# Reserve a static internal IP address for the PSC Endpoint
resource "google_compute_address" "sql_psc_ip" {
  name         = "${var.resource_prefix}-sql-psc-ip"
  project      = var.project_id
  region       = var.region
  subnetwork   = var.private_subnet_ids[0]
  address_type = "INTERNAL"
}

# PSC Endpoint for Cloud SQL for in-VPC clients
# This forwarding rule provides a stable, internal IP address within the VPC
# for clients like GCE VMs or Serverless connectors to connect to Cloud SQL.
resource "google_compute_forwarding_rule" "sql_psc_endpoint" {
  project               = var.project_id
  name                  = "${var.resource_prefix}-sql-psc-endpoint"
  region                = var.region
  ip_address            = google_compute_address.sql_psc_ip.self_link
  network               = var.vpc_id
  target                = google_sql_database_instance.mysql_instance.psc_service_attachment_link
  load_balancing_scheme = "" # Must be empty for PSC to a service attachment
  depends_on = [
    google_sql_database_instance.mysql_instance
  ]
}
