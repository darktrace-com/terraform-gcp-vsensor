#PCAPs bucket
output "pcaps_bucket_name" {
  value       = var.retention_time_days != 0 ? google_storage_bucket.vsensor_pcaps[0].name : null
  description = "The name of the bucket that stores the PCAPs."
}

output "pcaps_bucket_self_link" {
  value       = var.retention_time_days != 0 ? google_storage_bucket.vsensor_pcaps[0].self_link : null
  description = "The URI of the bucket that stores the PCAPs."
}

output "pcaps_bucket_url" {
  value       = var.retention_time_days != 0 ? google_storage_bucket.vsensor_pcaps[0].self_link : null
  description = "The  base URL of the bucket that stores the PCAPs."
}

output "service_account_vsensor_email" {
  value       = google_service_account.vsensor.email
  description = "The service account email."
}

#output "client_config_project" {
#  value       = data.google_client_config.vsensor.project
#  description = "The client config project."
#}

output "project_id" {
  value       = data.google_project.project.project_id
  description = "The project id."
}

output "project_number" {
  value       = data.google_project.project.number
  description = "The project number."
}

# new VPC
output "vpc_id" {
  value       = var.new_vpc_enable ? google_compute_network.vsensor[0].id : null
  description = "The ID of the new VPC."
}

output "vpc_name" {
  value       = var.new_vpc_enable ? google_compute_network.vsensor[0].name : null
  description = "The name of the new VPC."
}

output "vpc_self_link" {
  value       = var.new_vpc_enable ? google_compute_network.vsensor[0].self_link : null
  description = "The self_link of the new VPC."
}

output "mig_subnets_id" {
  value       = google_compute_subnetwork.vsensor.id
  description = "Subnet id where the vSensors are deployed."
}

# LB frontend IP
output "lb_ip" {
  value       = google_compute_forwarding_rule.vsensor.ip_address
  description = "LB fronend IP."
}

# Packet mirroring filter protocols
output "mirrored_protocols" {
  value       = local.mirroring_policy ? google_compute_packet_mirroring.vsensor[0].filter[0].ip_protocols : null
  description = "List of the packet mirroring protocols."
}

# MIG distribution across zones
output "mig_distribution_zones" {
  value       = local.mig_zone
  description = "Zones configured for vSensors managed instance group (MIG)."
}

# vSensor NAT External IP
output "nat_external_ip" {
  value       = google_compute_address.vsensor_nat_external.address
  description = "Public IP address used for NAT router to allow vSensors access to Darktrace cloud service / physical Darktrace deployment and software updates."
}

# Bastion External IP
output "bastion_external_ip" {
  value       = local.bastion ? google_compute_address.vsensor_bastion_external[0].address : null
  description = "Public IP address used for the Bastion VM."
}
