### Flux
resource "google_service_account" "flux" {
  account_id   = "fluxcd"
  display_name = "Flux CD"
}

data "google_kms_key_ring" "sops_key_ring" {
  location = var.region
  name     = "sops-kr"
}

data "google_kms_crypto_key" "flux" {
  name     = "flux"
  key_ring = data.google_kms_key_ring.sops_key_ring.self_link
}

resource "google_kms_crypto_key_iam_member" "flux" {
  crypto_key_id = data.google_kms_crypto_key.flux.id
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  member        = "serviceAccount:${google_service_account.flux.email}"
}

resource "google_service_account_iam_binding" "flux" {
  service_account_id = google_service_account.flux.name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${google_container_cluster.cluster.workload_identity_config[0].identity_namespace}[flux/flux]"]
}


### External DNS
resource "google_service_account" "external_dns" {
  account_id   = "external-dns"
  display_name = "External DNS"
}

resource "google_project_iam_member" "external_dns" {
  role   = "roles/dns.admin"
  member = "serviceAccount:${google_service_account.external_dns.email}"
}

resource "google_service_account_iam_binding" "external_dns" {
  service_account_id = google_service_account.external_dns.name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${google_container_cluster.cluster.workload_identity_config[0].identity_namespace}[system/external-dns]"]
}


### Cert Manager
resource "google_service_account" "cert_manager" {
  account_id   = "cert-manager"
  display_name = "Cert Manager"
}

resource "google_project_iam_member" "cert_manager" {
  role   = "roles/dns.admin"
  member = "serviceAccount:${google_service_account.cert_manager.email}"
}

resource "google_service_account_iam_binding" "cert_manager" {
  service_account_id = google_service_account.cert_manager.name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${google_container_cluster.cluster.workload_identity_config[0].identity_namespace}[system/cert-manager]"]
}



# Vault K8s
resource "google_service_account" "vault_k8s" {
  account_id   = "vault-k8s"
  display_name = "Vault K8s"
}

data "google_kms_key_ring" "vault_key_ring" {
  location = var.region
  name     = "vault-helm-unseal-kr"
}

data "google_kms_crypto_key" "vault_k8s" {
  name     = "vault-helm-unseal-key"
  key_ring = data.google_kms_key_ring.vault_key_ring.self_link
}

resource "google_kms_crypto_key_iam_member" "vault_k8s" {
  crypto_key_id = data.google_kms_crypto_key.vault_k8s.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.vault_k8s.email}"
}

resource "google_service_account_iam_binding" "vault_k8s" {
  service_account_id = google_service_account.vault_k8s.name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${google_container_cluster.cluster.workload_identity_config[0].identity_namespace}[consul/vault]"]
}


### Velero
resource "google_service_account" "velero" {
  account_id   = "velero"
  display_name = "Velero"
}

resource "google_storage_bucket_iam_member" "velero" {
  bucket = "fluxing"
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.velero.email}"
}

resource "google_service_account_iam_binding" "velero" {
  service_account_id = google_service_account.velero.name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${google_container_cluster.cluster.workload_identity_config[0].identity_namespace}[system/velero-server]"]
}
