terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.49.1"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.49.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "gcs" {
    bucket = "tfstate-<YOUR_GCP_PROJECT_ID>" # <-- UPDATE THIS
    prefix = "gcp-debezium-mysql-to-pubsub-bigquery/terraform"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Instantiate the Project APIs Module to enable all necessary services
module "project-apis" {
  source     = "../../modules/project-apis"
  project_id = var.project_id
}

# Instantiate the Network Module
module "network" {
  source = "../../modules/network"
  project_id            = var.project_id
  region                = var.region
  vpc_name              = var.vpc_name
  public_subnet_cidr    = var.public_subnet_cidr
  private_subnet_cidr   = var.private_subnet_cidr
  psc_subnet_cidr_range = var.psc_subnet_cidr_range
}

# Instantiate the Datastream to GCS Module
module "debezium-source" {
  source = "../../modules/debezium-source"

  # GCP Project Details
  project_id = var.project_id
  region     = var.region

  # Input from Network Module
  vpc_id = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  private_service_connection_network = module.network.private_service_connection_network

  # Cloud SQL (MySQL) Configuration
  allowed_psc_projects = var.allowed_psc_projects
  db_instance_name     = var.db_instance_name
  db_version           = var.db_version
  db_tier              = var.db_tier

  # Explicit dependency on API activation
  enabled_apis = module.project-apis.enabled_apis
}

# Instantiate the GCE Client Module for testing PSC connection
module "gce-client" {
  source            = "../../modules/gce-client"
  project_id        = var.project_id
  region            = var.region
  zone              = var.zone
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.private_subnet_ids[0]
  psc_endpoint_ip   = module.debezium-source.cloud_sql_psc_endpoint_ip
  db_user           = module.debezium-source.datastream_user_name
  db_password       = module.debezium-source.datastream_user_password
  pubsub_topic_name = var.pubsub_topic_name
}

# Instantiate the BigQuery Sink Module
module "bigquery-sink" {
  source            = "../../modules/bigquery-sink"
  project_id        = var.project_id
  region            = var.region
  pubsub_topic_name = module.gce-client.pubsub_topic_name
}
