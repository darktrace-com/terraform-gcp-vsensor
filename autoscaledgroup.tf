resource "google_compute_instance_template" "vsensor" {
  name_prefix = "${local.deployment_id}-vsensor-template"

  tags = [
    "darktrace-vsensor-mirroring"
  ]

  network_interface {
    subnetwork = google_compute_subnetwork.vsensor.self_link
  }

  can_ip_forward = true # Allow RESPOND/Network packets

  machine_type = var.mig_instance_type

  service_account {
    email  = google_service_account.vsensor.email
    scopes = ["cloud-platform"]
  }

  disk {
    source_image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-balanced"
    labels = {
      darktrace-vsensor = "true"
    }
  }
  metadata = {
    startup-script = templatefile("${path.module}/source/startup-script.sh.tftpl", {
      sm_update_key          = var.sm_update_key
      sm_push_token          = var.sm_push_token
      sm_ossensor_hmac       = var.sm_ossensor_hmac
      dt_instance_hostname   = var.dt_instance_hostname
      dt_instance_port       = var.dt_instance_port
      ossensor_lb_ip         = local.lb_ip
      pcap_bucket_name       = var.retention_time_days == 0 ? "" : google_storage_bucket.vsensor_pcaps[0].name
      ssh_iap                = var.ssh_iap
      service_account_email  = google_service_account.vsensor.email
      GCP_CLOUD_OPS_TEMPLATE = templatefile("${path.module}/source/cloud-ops-template.yaml.tftpl", {})
    })

    ssh-keys = var.mig_ssh_user_key
  }
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_storage_bucket.vsensor_pcaps]
}

resource "google_compute_region_instance_group_manager" "vsensor" {

  #Changing the distribution policy does not work in `update in-place` fashion
  #WA is to make terraform do `create replacement and then destroy` by giving a new name every time `mig_zone` is changed
  name = join("-", [local.deployment_id, "group", local.mig_zone_hash])

  description = "Managed Instance Group for Darktrace vSensor."
  provider    = google-beta #Required for min_ready_sec
  project     = google_service_account.vsensor.project

  base_instance_name = "${local.deployment_id}-vsensor"
  region             = var.region

  distribution_policy_zones = local.mig_zone

  update_policy {
    type            = "PROACTIVE"
    minimal_action  = "REPLACE"
    max_surge_fixed = local.max_surge_fixed
    min_ready_sec   = 180
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.vsensor.self_link
    initial_delay_sec = 600
  }

  version {
    instance_template = google_compute_instance_template.vsensor.self_link
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_compute_router_nat.vsensor]
}

resource "google_compute_region_autoscaler" "vsensor" {
  provider = google-beta #Required for the scale_down_control block

  #Changing the distribution policy does not work in `update in-place` fashion
  #WA is to make terraform do `create replacement and then destroy` by giving a new name every time `mig_zone` is changed
  name = join("-", [local.deployment_id, "autoscale", local.mig_zone_hash])

  project = google_service_account.vsensor.project
  region  = var.region
  target  = google_compute_region_instance_group_manager.vsensor.self_link

  autoscaling_policy {
    max_replicas    = var.mig_max_size
    min_replicas    = var.mig_min_size
    cooldown_period = 300
    scale_down_control {
      time_window_sec = 600
      max_scaled_down_replicas {
        fixed = 1
      }
    }

    cpu_utilization {
      target            = 0.75
      predictive_method = "OPTIMIZE_AVAILABILITY"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "google_compute_health_check" "vsensor" {
  name = "${local.deployment_id}-healthcheck"

  https_health_check {
    port         = "443"
    request_path = "/healthcheck"
  }
}
