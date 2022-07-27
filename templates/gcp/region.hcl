# Common variables for the region. This is automatically pulled in in the root
# terragrunt.hcl configuration to configure the remote state bucket.
locals {
  aws_region = "awsdefault"
  gcp_region = "gcpdefault"
}
