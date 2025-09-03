# Create a BigQuery dataset to store the CDC data.
resource "google_bigquery_dataset" "debezium_sink" {
  project     = var.project_id
  dataset_id  = var.dataset_name
  location    = var.region
  description = "Dataset to store CDC events from Debezium."
}

# Create the BigQuery table.
# The schema is defined to accept Pub/Sub's message format for BigQuery subscriptions.
# It includes the raw message data, subscription name, message ID, and attributes.
resource "google_bigquery_table" "cdc_events" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.debezium_sink.dataset_id
  table_id   = var.table_name

  # When a Pub/Sub subscription writes to BigQuery, it uses a fixed schema.
  # 'data' contains the message payload, and 'attributes' contains the message attributes.
  schema = jsonencode([
    {
      "name" : "data",
      "type" : "JSON"
    },
    {
      "name" : "attributes",
      "type" : "JSON"
    },
    {
      "name" : "message_id",
      "type" : "STRING"
    },
    {
      "name" : "publish_time",
      "type" : "TIMESTAMP"
    },
    {
      "name" : "subscription_name",
      "type" : "STRING"
    }
  ])

  # Optional: Enable partitioning for better performance and cost management.
  time_partitioning {
    type  = "DAY"
    field = "publish_time"
  }
}
