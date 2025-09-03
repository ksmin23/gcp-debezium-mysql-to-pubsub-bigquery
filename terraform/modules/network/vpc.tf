# --- 1. VPC Network ---
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
}

data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

# --- 2. Subnets ---
resource "google_compute_subnetwork" "public" {
  for_each = toset(data.google_compute_zones.available.names)

  name          = "public-subnet-${each.key}"
  ip_cidr_range = cidrsubnet(var.public_subnet_cidr, 8, index(data.google_compute_zones.available.names, each.key))
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "private" {
  for_each = toset(data.google_compute_zones.available.names)

  name                     = "private-subnet-${each.key}"
  ip_cidr_range            = cidrsubnet(var.private_subnet_cidr, 8, index(data.google_compute_zones.available.names, each.key))
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "datastream_psc_subnet" {
  name          = "snet-for-datastream-psc"
  ip_cidr_range = var.psc_subnet_cidr_range
  network       = google_compute_network.vpc.id
  region        = var.region
}

# --- 3. Cloud NAT & Router ---
resource "google_compute_router" "router" {
  name    = "${google_compute_network.vpc.name}-router"
  network = google_compute_network.vpc.id
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "${google_compute_network.vpc.name}-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = google_compute_subnetwork.private
    content {
      name                    = subnetwork.value.id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# --- 4. Firewall Rules ---
resource "google_compute_firewall" "allow_internal" {
  name    = "${google_compute_network.vpc.name}-allow-internal"
  network = google_compute_network.vpc.self_link
  allow {
    protocol = "all"
  }
  source_ranges = concat(
    [for s in google_compute_subnetwork.public : s.ip_cidr_range],
    [for s in google_compute_subnetwork.private : s.ip_cidr_range],
  )
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${google_compute_network.vpc.name}-allow-ssh"
  network = google_compute_network.vpc.self_link
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# --- 5. Service Networking for Cloud SQL ---
# NOTE: This Private Service Access (PSA) configuration is a prerequisite for provisioning
# a Cloud SQL instance with a private IP. However, all actual client connections
# (from Datastream, GCE, etc.) will be made through a Private Service Connect (PSC)
# endpoint created in the 02-app-infra module for a more modern and flexible architecture.
resource "google_compute_global_address" "private_ip_address" {
  name          = "gcp-servicenetworking-vpc-peering-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = concat(var.existing_peering_ranges, [google_compute_global_address.private_ip_address.name])
}
