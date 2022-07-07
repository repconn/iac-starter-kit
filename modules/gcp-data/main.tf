# This module standardizes the output of existing Google Cloud resources

data "google_compute_network" "this" {
  name = "default-us-east1"
}

output "google_compute_network_id" {
  value = data.google_compute_network.this.id
}
