variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be created."
  type        = string
}

variable "zone" {
  description = "The GCP zone for the GCE client instance. Should be in the same region."
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC network."
  type        = string
  default     = "gcp-ds-cdc-vpc"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet."
  type        = string
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet."
  type        = string
}

variable "psc_subnet_cidr_range" {
  description = "The CIDR block for the Datastream PSC subnet. This will be passed to the 'psc_subnet_cidr_range' variable in the network module."
  type        = string
}

variable "allowed_psc_projects" {
  description = "A list of consumer projects allowed to connect via PSC. Must include your project ID."
  type        = list(string)
}

variable "db_instance_name" {
  description = "The name of the Cloud SQL database instance."
  type        = string
  default     = "mysql-src-ds"
}

variable "db_version" {
  description = "The version for the Cloud SQL for MySQL instance."
  type        = string
  default     = "MYSQL_8_0"
}

variable "db_tier" {
  description = "The machine type for the Cloud SQL instance."
  type        = string
  default     = "db-n1-standard-2"
}

variable "pubsub_topic_name" {
  description = "The name of the Pub/Sub topic for Debezium."
  type        = string
  default     = "debezium-topic"
}
