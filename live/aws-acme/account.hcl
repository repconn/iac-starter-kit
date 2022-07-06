# Account-level variables. These are automatically pulled in to configure
# the remote state bucket in the root terragrunt.hcl configuration.
locals {
  aws_profile = "default"
  gcp_project = ""
}
