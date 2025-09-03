# Enable all required APIs for the project in one central place.
resource "google_project_service" "project_services" {
  for_each = toset([
    "serviceusage.googleapis.com",
    "servicenetworking.googleapis.com",
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "pubsub.googleapis.com"
  ])
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}
