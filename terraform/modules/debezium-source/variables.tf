# terraform/modules/datastream-gcs/variables.tf

variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be created."
  type        = string
  default     = "us-central1"
}

variable "vpc_id" {
  description = "The ID of the VPC network."
  type        = string
}

# variable "vpc_self_link" {
#   description = "The self-link of the VPC network."
#   type        = string
# }

variable "private_subnet_ids" {
  description = "A list of the private subnet IDs."
  type        = list(string)
}

# variable "datastream_psc_subnet_self_link" {
#   description = "The self-link of the Datastream PSC subnet."
#   type        = string
# }

# variable "datastream_psc_subnet_cidr" {
#   description = "The CIDR of the Datastream PSC subnet."
#   type        = string
# }

variable "db_instance_name" {
  description = "The name of the Cloud SQL database instance."
  type        = string
  default     = "mysql-src-ds"
}

variable "db_version" {
  description = "The version of the Cloud SQL database."
  type        = string
  default     = "MYSQL_8_0"
}

variable "db_tier" {
  description = "The machine type for the Cloud SQL database."
  type        = string
  default     = "db-n1-standard-2"
}

variable "allowed_psc_projects" {
  description = "A list of consumer projects allowed to connect via PSC. Must include your project ID."
  type        = list(string)
}

# variable "datastream_psc_name" {
#   description = "The name for the Datastream private service connection."
#   type        = string
#   default     = "mysql-private-connection-psc"
# }

# variable "datastream_src_conn_profile_name" {
#   description = "The name of the connection profile."
#   type        = string
#   default     = "mysql-source-conn-profile"
# }

variable "private_service_connection_network" {
  description = "The network resource from the private service connection, used for explicit dependency."
  type        = any
}

variable "resource_prefix" {
  description = "A prefix used for naming resources to ensure uniqueness and logical grouping."
  type        = string
  default     = "gcp-ds-cdc"
}

variable "enabled_apis" {
  description = "The list of enabled APIs, used for explicit dependency."
  type        = any
  default     = []
}

# BigQuery Configuration
# variable "bigquery_dataset_name" {
#   description = "The name of the BigQuery dataset to create for replica tables."
#   type        = string
# }

# variable "bigquery_staging_dataset_name" {
#   description = "The name of the BigQuery dataset to create for staging tables."
#   type        = string
# }

# variable "bigquery_dataset_location" {
#   description = "The location for the BigQuery dataset."
#   type        = string
#   default     = "US"
# }