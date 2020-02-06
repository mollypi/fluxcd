provider "google" {
  project = "ck-gcp-training"
  region  = var.region
}
provider "google-beta" {
  project = "ck-gcp-training"
  region  = var.region
}

data "google_client_config" "current" {}

data "google_container_engine_versions" "gke_versions" {
  location = var.region
}

resource "google_container_cluster" "cluster" {
  provider = google-beta

  depends_on = [google_compute_security_policy.allow_crowe]

  name               = "fluxing"
  min_master_version = data.google_container_engine_versions.gke_versions.latest_master_version

  location   = var.region
  network    = google_compute_network.network.name
  subnetwork = google_compute_subnetwork.subnetwork.name

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {}

  workload_identity_config {
    identity_namespace = "${data.google_client_config.current.project}.svc.id.goog"
  }
  network_policy {
    provider = "CALICO"
    enabled  = true
  }

  addons_config {
    network_policy_config {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    # istio_config {
    #   disabled = false
    #   auth     = "AUTH_MUTUAL_TLS"
    # }
  }

  pod_security_policy_config {
    enabled = false
  }

  private_cluster_config {
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
    enable_private_endpoint = false
  }
  master_authorized_networks_config {
    cidr_blocks {
      display_name = "adriatic_building"
      cidr_block   = "89.36.70.11/32"
    }
    cidr_blocks {
      display_name = "global_protect_uk"
      cidr_block   = "18.175.30.125/32"
    }
  }

  monitoring_service = "none"
  logging_service    = "none"
}

resource "google_container_node_pool" "standard" {
  provider = google-beta

  name     = "standard"
  cluster  = google_container_cluster.cluster.name
  location = var.region

  version = google_container_cluster.cluster.master_version

  initial_node_count = 1
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  node_config {
    machine_type = "n1-standard-2"
    image_type   = "COS_CONTAINERD"
    disk_size_gb = "30"
    preemptible  = false

    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }

    tags = ["gke-${google_container_cluster.cluster.name}", "standard-np"]
  }

  timeouts {
    update = "60m"
  }
}

