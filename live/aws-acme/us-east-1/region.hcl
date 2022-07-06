# Common variables for the region. This is automatically pulled in in the root
# terragrunt.hcl configuration to configure the remote state bucket.
locals {
  aws_region = "us-east-1"
  gcp_region = ""
}
