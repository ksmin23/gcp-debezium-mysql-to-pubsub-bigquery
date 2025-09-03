# Get project details, including the project number needed for the service agent email.
data "google_project" "project" {}

# --- Dead Letter Queue (DLQ) Resources ---

# Create a separate topic to act as the Dead Letter Queue.
resource "google_pubsub_topic" "dead_letter_topic" {
  project                    = var.project_id
  name                       = "${var.pubsub_topic_name}-dlq"
  message_retention_duration = var.dlq_topic_retention_duration
}

# Create a subscription to the DLQ topic to inspect failed messages.
resource "google_pubsub_subscription" "dead_letter_subscription" {
  project                    = var.project_id
  name                       = "${google_pubsub_topic.dead_letter_topic.name}-sub"
  topic                      = google_pubsub_topic.dead_letter_topic.name
  message_retention_duration = "604800s" # 7 days
  ack_deadline_seconds       = 60
}


# --- IAM Permissions for Service Agents ---

# Grant the Pub/Sub service agent the necessary permissions on the BigQuery dataset.
resource "google_bigquery_dataset_iam_member" "pubsub_writer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.debezium_sink.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# Grant the Pub/Sub service agent permission to publish to the dead-letter topic.
resource "google_pubsub_topic_iam_member" "dlq_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.dead_letter_topic.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# Grant the Pub/Sub service agent permission to acknowledge messages on the main subscription.
# This is required for the service to be able to send the message to the DLQ.
resource "google_pubsub_subscription_iam_member" "main_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.bigquery_subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}


# --- Main BigQuery Subscription ---

# Create a Pub/Sub subscription that writes messages from the topic to the BigQuery table.
resource "google_pubsub_subscription" "bigquery_subscription" {
  project = var.project_id
  name    = "${var.pubsub_topic_name}-to-bigquery-sub"
  topic   = "projects/${var.project_id}/topics/${var.pubsub_topic_name}"

  # Configure the subscription to write directly to BigQuery.
  bigquery_config {
    table = "${var.project_id}:${google_bigquery_dataset.debezium_sink.dataset_id}.${google_bigquery_table.cdc_events.table_id}"

    # Add metadata such as message_id and publish_time to the BigQuery table.
    write_metadata = true

    # Use the topic's schema. If the topic has a schema, Pub/Sub will validate
    # messages against it and write them to BigQuery in the corresponding format.
    # If the topic has no schema, set this to false.
    use_topic_schema = false

    # If set to true, fields in the message that are not in the BigQuery schema will be dropped.
    # If false, messages with extra fields will be sent to the dead-letter topic.
    drop_unknown_fields = true
  }

  # Configure the dead-letter policy.
  # After 5 delivery attempts, the message will be sent to the dead_letter_topic.
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter_topic.id
    max_delivery_attempts = 5
  }

  # Ensure the IAM permission for the Pub/Sub service agent is in place before creating the subscription.
  depends_on = [
    google_bigquery_dataset_iam_member.pubsub_writer
  ]
}
