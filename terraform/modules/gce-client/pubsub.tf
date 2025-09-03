locals {
  # Extract the prefix from the full topic name variable (e.g., "debezium-topic" from "debezium-topic.testdb.retail_trans")
  topic_prefix = split(".", var.pubsub_topic_name)[0]
}

# Creates the specific topic based on the full variable name.
# e.g., "debezium-topic.testdb.retail_trans"
resource "google_pubsub_topic" "debezium_topic" {
  project                    = var.project_id
  name                       = var.pubsub_topic_name
  message_retention_duration = var.topic_retention_duration
}

# Creates a default/main topic based on the extracted prefix.
# e.g., "debezium-topic"
resource "google_pubsub_topic" "debezium_default_topic" {
  project                    = var.project_id
  name                       = local.topic_prefix
  message_retention_duration = var.topic_retention_duration
}

# Grant the GCE VM's service account permission to publish to Pub/Sub topics.
resource "google_project_iam_member" "pubsub_publisher_for_debezium" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}
