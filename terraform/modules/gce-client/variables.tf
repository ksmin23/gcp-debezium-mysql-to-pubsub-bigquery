variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be created."
  type        = string
}

variable "zone" {
  description = "The GCP zone for the GCE instance."
  type        = string
}

variable "instance_name" {
  description = "The name of the GCE instance."
  type        = string
  default     = "mysql-client-vm"
}

variable "machine_type" {
  description = "The machine type for the GCE instance."
  type        = string
  default     = "e2-medium"
}

variable "vpc_id" {
  description = "The ID of the VPC network to which the instance will be attached."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnetwork to which the instance will be attached."
  type        = string
}

variable "psc_endpoint_ip" {
  description = "The IP address of the PSC endpoint for Cloud SQL."
  type        = string
}

variable "db_user" {
  description = "The username for the database connection test."
  type        = string
}

variable "db_password" {
  description = "The password for the database connection test."
  type        = string
  sensitive   = true
}

variable "pubsub_topic_name" {
  description = "The name of the Pub/Sub topic for Debezium."
  type        = string
}

variable "topic_retention_duration" {
  description = "The message retention duration for the Pub/Sub topics, in seconds (e.g., '604800s' for 7 days)."
  type        = string
  default     = "604800s" # 7 days
}