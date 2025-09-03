output "gce_client_instance_name" {
  description = "The name of the GCE client instance."
  value       = google_compute_instance.mysql_client_vm.name
}

output "gce_client_instance_private_ip" {
  description = "The private IP address of the GCE client instance."
  value       = google_compute_instance.mysql_client_vm.network_interface[0].network_ip
}

output "gce_client_zone" {
  description = "The zone of the GCE client VM."
  value       = var.zone
}

output "pubsub_topic_name" {
  description = "The name of the specific Pub/Sub topic based on the full variable."
  value       = google_pubsub_topic.debezium_topic.name
}
