#data "google_client_config" "vsensor" {}

data "google_project" "project" {
  project_id = var.project_id
}

data "google_compute_network" "default" {
  count = var.new_vpc_enable ? 0 : 1
  name  = var.existing_vpc_name
}

data "google_compute_zones" "available" {
  region = var.region
}

data "google_secret_manager_secret" "update_key" {
  secret_id = var.sm_update_key
}

data "google_secret_manager_secret" "push_token" {
  secret_id = var.sm_push_token
}

data "google_secret_manager_secret" "ossensor_hmac" {
  count = length(var.sm_ossensor_hmac) == 0 ? 0 : 1

  secret_id = var.sm_ossensor_hmac
}
