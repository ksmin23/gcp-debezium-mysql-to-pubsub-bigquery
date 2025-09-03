output "cloud_sql_instance_name" {
  description = "The name of the Cloud SQL for MySQL instance."
  value       = google_sql_database_instance.mysql_instance.name
}

output "cloud_sql_instance_private_ip" {
  description = "The private IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.private_ip_address
  sensitive   = true
}

output "datastream_user_name" {
  description = "The username for the 'datastream' SQL user."
  value       = google_sql_user.datastream_user.name
}

output "datastream_user_password" {
  description = "The password for the 'datastream' SQL user."
  value       = random_password.ds_password.result
  sensitive   = true
}

output "admin_user_name" {
  description = "The username for the database admin."
  value       = google_sql_user.admin_user.name
}

output "admin_user_password" {
  description = "The password for the database admin user."
  value       = random_password.admin_password.result
  sensitive   = true
}

output "cloud_sql_psc_endpoint_name" {
  description = "The name of the PSC Endpoint for Cloud SQL."
  value       = google_compute_forwarding_rule.sql_psc_endpoint.name
}

output "cloud_sql_psc_endpoint_ip" {
  description = "The internal IP address of the PSC Endpoint for Cloud SQL. Use this IP for all in-VPC connections."
  value       = google_compute_forwarding_rule.sql_psc_endpoint.ip_address
}

# output "bigquery_dataset_id" {
#   description = "The ID of the BigQuery dataset."
#   value       = google_bigquery_dataset.analytics_dataset.dataset_id
# }

# output "bigquery_staging_dataset_id" {
#   description = "The ID of the BigQuery staging dataset."
#   value       = google_bigquery_dataset.staging_dataset.dataset_id
# }
