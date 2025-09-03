variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be created."
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  description = "The name of the VPC network."
  type        = string
  default     = "gcp-ds-cdc-vpc"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnets."
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnets."
  type        = string
  default     = "10.1.0.0/16"
}

variable "psc_subnet_cidr_range" {
  description = "A free CIDR range of /29 for the Datastream PSC subnet."
  type        = string
}

variable "existing_peering_ranges" {
  description = "A list of existing peering ranges to preserve in the service networking connection."
  type        = list(string)
  default     = []
}
