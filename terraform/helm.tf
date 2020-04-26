provider "helm" {
  kubernetes {
    load_config_file = false

    host                   = google_container_cluster.cluster.endpoint
    token                  = data.google_client_config.current.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  version          = "1.10.0" # 1.11 broke https://github.com/terraform-providers/terraform-provider-kubernetes/issues/759
  load_config_file = false

  host                   = google_container_cluster.cluster.endpoint
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)
}

# Flux

data "helm_repository" "flux" {
  name = "fluxcd"
  url  = "https://charts.fluxcd.io"
}

resource "helm_release" "flux" {
  depends_on = [kubernetes_secret.flux-ssh, kubernetes_secret.fluxrecv-config]

  name       = "flux"
  repository = data.helm_repository.flux.metadata.0.name
  chart      = "flux"
  version    = "1.3.0"
  namespace  = "flux"

  values = [
    file("k8s/flux.yaml")
  ]
}

resource "helm_release" "flux_helm_operator" {
  depends_on = [kubernetes_namespace.flux]

  name       = "flux-helm-operator"
  repository = data.helm_repository.flux.metadata.0.name
  chart      = "helm-operator"
  version    = "1.0.1"
  namespace  = "flux"

  values = [
    file("k8s/flux-helm-operator.yaml")
  ]
}

resource "kubernetes_namespace" "flux" {
  depends_on = [google_container_node_pool.standard]

  metadata {
    name = "flux"
    labels = {
      name            = "flux"
    }
  }
}

resource "kubernetes_secret" "flux-ssh" {
  depends_on = [kubernetes_namespace.flux]

  metadata {
    name      = "flux-ssh"
    namespace = "flux"
  }

  data = {
    identity = file("k8s/flux_id_rsa")
  }

  lifecycle {
    # Terraform wants to change annotations added by flux without this
    ignore_changes = [metadata.0.annotations]
  }
}

resource "kubernetes_secret" "fluxrecv-config" {
  depends_on = [kubernetes_namespace.flux]

  metadata {
    name      = "fluxrecv-config"
    namespace = "flux"
  }

  data = {
    "github.key"    = file("k8s/github.key")
    "fluxrecv.yaml" = file("k8s/fluxrecv.yaml")
  }
}
