output "vpc_id" {
  description = "The ID of the VPC network."
  value       = google_compute_network.vpc.id
}

output "vpc_self_link" {
  description = "The self-link of the VPC network."
  value       = google_compute_network.vpc.self_link
}

output "network_name" {
  description = "The name of the VPC network."
  value       = google_compute_network.vpc.name
}

output "datastream_psc_subnet_self_link" {
  description = "The self-link of the Datastream PSC subnet."
  value       = google_compute_subnetwork.datastream_psc_subnet.self_link
}

output "datastream_psc_subnet_cidr" {
  description = "The CIDR of the Datastream PSC subnet."
  value       = google_compute_subnetwork.datastream_psc_subnet.ip_cidr_range
}

output "private_subnet_ids" {
  description = "A list of the private subnet IDs."
  value       = [for s in google_compute_subnetwork.private : s.id]
}

output "private_subnet_self_links" {
  description = "A list of the private subnet self-links."
  value       = [for s in google_compute_subnetwork.private : s.self_link]
}

output "private_subnet_cidrs" {
  description = "A list of the private subnet CIDRs."
  value       = [for s in google_compute_subnetwork.private : s.ip_cidr_range]
}

output "private_service_connection_network" {
  description = "The network resource from the private service connection, used for explicit dependency."
  value       = google_service_networking_connection.private_vpc_connection.network
}