
resource "google_compute_network" "network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name                     = var.subnetwork_name
  ip_cidr_range            = "10.0.0.0/16"
  region                   = var.region
  network                  = google_compute_network.network.self_link
  private_ip_google_access = true
}

# SSH FW rule for IAP
resource "google_compute_firewall" "iap_ssh" {
  name    = "iap-ssh"
  network = google_compute_network.network.self_link

  allow {
    ports    = [22]
    protocol = "tcp"
  }

  source_ranges = ["35.235.240.0/20"]
}

## Vault Injector FW
# apiserver needs access to vault auto injector for calls to cert-manager webhook pod
resource "google_compute_firewall" "vault_agent_injector_fw" {
  name    = "vault-agent-injector-apiserver"
  network = google_compute_network.network.self_link

  allow {
    ports    = [8080]
    protocol = "tcp"
  }

  target_tags = ["gke-${google_container_cluster.cluster.name}"]

  source_ranges = [google_container_cluster.cluster.private_cluster_config.0.master_ipv4_cidr_block]
}

# Cloud NAT

resource "google_compute_router" "router" {
  name    = "cloud-router"
  network = google_compute_network.network.self_link
}

resource "google_compute_router_nat" "cloud_nat" {
  name                               = "cloudnat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
