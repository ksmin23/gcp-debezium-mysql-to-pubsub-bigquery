# 0. Get the default compute service account to grant it Pub/Sub publisher permissions.
data "google_compute_default_service_account" "default" {
  project = var.project_id
}

# 1. Create a GCS bucket for temporary file storage (random ID ensures a unique name)
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "google_storage_bucket" "debezium_files_bucket" {
  project                       = var.project_id
  name                          = "debezium-server-files-${random_id.bucket_suffix.hex}"
  location                      = var.region
  force_destroy                 = true # This will delete all objects in the bucket when the bucket is destroyed.
  uniform_bucket_level_access = true
}

# 2. Upload all files from the local debezium-server folder to the GCS bucket.
#    This code finds files relative to the project root where terraform is executed.
#    To avoid pathing issues, we use `path.module` to build a reliable relative path.
resource "google_storage_bucket_object" "debezium_server_files" {
  for_each   = fileset("${path.module}/../../../debezium-server", "**/*") # Locate the debezium-server folder from the module's directory.
  bucket     = google_storage_bucket.debezium_files_bucket.name
  name       = "debezium-server/${each.value}"
  source     = "${path.module}/../../../debezium-server/${each.value}"
  depends_on = [
    google_storage_bucket.debezium_files_bucket
  ]
}