# Account-level variables. These are automatically pulled in to configure
# the remote state bucket in the root terragrunt.hcl configuration.
locals {
  gcp_project = "default"
}

# Configure Terragrunt to automatically create an encrypted S3 bucket
# with versioning enabled and store tfstate files in it
remote_state {
  backend = "gcs"

  generate = {
    path = "_backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "${local.gcp_project}-terraform-state"
    skip_bucket_versioning = false
  }
}
