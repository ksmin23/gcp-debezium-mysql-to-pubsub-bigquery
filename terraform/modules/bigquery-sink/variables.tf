variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be created."
  type        = string
}

variable "dataset_name" {
  description = "The name of the BigQuery dataset."
  type        = string
  default     = "debezium_sink"
}

variable "table_name" {
  description = "The name of the BigQuery table to store CDC data."
  type        = string
  default     = "cdc_events"
}

variable "pubsub_topic_name" {
  description = "The name of the Pub/Sub topic to subscribe to."
  type        = string
}

variable "dlq_topic_retention_duration" {
  description = "The message retention duration for the DLQ topic, in seconds."
  type        = string
  default     = "604800s" # 7 days
}
