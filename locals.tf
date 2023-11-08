locals {
  network_name      = var.new_vpc_enable ? google_compute_network.vsensor[0].name : data.google_compute_network.default[0].name
  network_self_link = var.new_vpc_enable ? google_compute_network.vsensor[0].self_link : data.google_compute_network.default[0].self_link
  network_id        = var.new_vpc_enable ? google_compute_network.vsensor[0].id : data.google_compute_network.default[0].id

  retention_time_secs = var.retention_time_days * 60 * 60 * 24

  max_surge_fixed = length(var.mig_zone) == 0 ? length(data.google_compute_zones.available.names) : length(var.mig_zone)
  mig_zone        = length(var.mig_zone) == 0 ? data.google_compute_zones.available.names : var.mig_zone

  mirroring_policy = length(var.mirrored_subnets) == 0 ? false : true

  #Workaround to change the ip_protocols value from Allow specific protocols to Allow all protocols
  filter_description = length(var.mirrored_protocols) == 0 ? "All protocols" : "Specific protocols"

  #The vSensors should be aware of the Load Balancer's IP and for that reason the LB will have IP explicitly assigned (rather than being auto assigned by Google Cloud).
  #To make sure this IP is not ephemeral, a static internal IP address for the LB will be reserved (from the mig cidr block).
  #In every subnet Google reserve four IP addresses in the primary IP range - the first two and the last two (https://cloud.google.com/vpc/docs/subnets#reserved_ip_addresses_in_every_subnet).
  #The 3rd largest IP seems to be a good candidate to be reserved for the LB.
  lb_ip = cidrhost(var.mig_subnet_cidr, -3)

  mig_zone_hash = md5(join("", local.mig_zone))

  bastion = var.new_vpc_enable && var.bastion_enable ? true : false

  #If var.bastion_ssh_cidr is empty then the firewall will be created with source_ranges 0.0.0.0/0, i.e. port 22/tcp on the Bastion will be wide open; the below to is prevent this
  bastion_fw = length(var.bastion_ssh_cidr) != 0 && local.bastion ? true : false
}
