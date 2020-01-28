
# Cloud Armor policy
resource "google_compute_security_policy" "allow_crowe" {
  name = "allow-crowe"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["89.36.70.11/32", "18.175.30.125/32"]
      }
    }
    description = "Allow Ingress from home"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default deny all"
  }
}
