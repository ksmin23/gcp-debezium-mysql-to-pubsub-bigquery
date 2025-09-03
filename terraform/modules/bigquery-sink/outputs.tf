output "dataset_id" {
  description = "The ID of the BigQuery dataset."
  value       = google_bigquery_dataset.debezium_sink.dataset_id
}

output "table_id" {
  description = "The ID of the BigQuery table."
  value       = google_bigquery_table.cdc_events.table_id
}

output "bigquery_subscription_name" {
  description = "The name of the main BigQuery subscription."
  value       = google_pubsub_subscription.bigquery_subscription.name
}

output "dead_letter_topic_name" {
  description = "The name of the Dead Letter Queue (DLQ) topic."
  value       = google_pubsub_topic.dead_letter_topic.name
}

output "dead_letter_subscription_name" {
  description = "The name of the subscription to the DLQ topic."
  value       = google_pubsub_subscription.dead_letter_subscription.name
}
