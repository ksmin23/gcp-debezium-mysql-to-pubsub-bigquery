# Create a BigQuery dataset to store the CDC data.
resource "google_bigquery_dataset" "debezium_sink" {
  project     = var.project_id
  dataset_id  = var.dataset_name
  location    = var.region
  description = "Dataset to store CDC events from Debezium."
}

# Create the BigQuery table that will act as the data sink.
# Important: Before starting the Debezium Server, you must ensure this table has been created,
# as its schema is derived from the source database table.
resource "google_bigquery_table" "cdc_events" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.debezium_sink.dataset_id
  table_id   = var.table_name

  deletion_protection = true

  table_constraints {
    primary_key {
      columns = ["trans_id"]
    }
  }

  # When a Pub/Sub subscription writes to BigQuery, it uses the schema of the target BigQuery table.
  # Therefore, this table's schema must be defined to match the structure of the source MySQL table.
  # The schema is defined based on the Debezium CDC event structure after SMT.
  schema = jsonencode([
    {
      "name" : "trans_id",
      "type" : "INTEGER",
      "mode" : "REQUIRED"
    },
    {
      "name" : "customer_id",
      "type" : "STRING",
      "mode" : "REQUIRED",
      "maxLength": "12"
    },
    {
      "name" : "event",
      "type" : "STRING",
      "mode" : "NULLABLE",
      "maxLength": "10"
    },
    {
      "name" : "sku",
      "type" : "STRING",
      "mode" : "REQUIRED",
      "maxLength": "10"
    },
    {
      "name" : "amount",
      "type" : "INTEGER",
      "mode" : "REQUIRED"
    },
    {
      "name" : "device",
      "type" : "STRING",
      "mode" : "NULLABLE",
      "maxLength": "10"
    },
    {
      "name" : "trans_datetime",
      "type" : "TIMESTAMP",
      "mode" : "NULLABLE"
    },
    {
      "name" : "__op",
      "type" : "STRING",
      "mode" : "NULLABLE"
    },
    {
      "name" : "__table",
      "type" : "STRING",
      "mode" : "NULLABLE"
    },
    {
      "name" : "__source_ts_ms",
      "type" : "INTEGER",
      "mode" : "NULLABLE"
    },
    {
      "name" : "__deleted",
      "type" : "BOOLEAN",
      "mode" : "NULLABLE"
    }
  ])

  # Optional: Enable partitioning for better performance and cost management.
  time_partitioning {
    type  = "DAY"
    field = "trans_datetime"
  }
}
