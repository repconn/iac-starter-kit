# Empty variables. These are automatically pulled in to configure
# the remote state bucket in the root terragrunt.hcl configuration.
locals {
  aws_profile = ""
  aws_region  = ""
  gcp_project = ""
  gcp_region  = ""
  environment = ""
}
