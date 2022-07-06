# Common variables for the region. This is automatically pulled in in the root
# terragrunt.hcl configuration to configure the remote state bucket.
locals {
  gcp_region = "us-west1"
}
