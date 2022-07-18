# Account-level variables. These are automatically pulled in to configure
# the remote state bucket in the root terragrunt.hcl configuration.
locals {
  aws_profile = "default"
}

# Configure Terragrunt to automatically create an encrypted S3 bucket
# with versioning enabled and store tfstate files in it
remote_state {
  backend = "s3"

  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket                 = "${local.aws_profile}-terraform-state"
    key                    = "${path_relative_to_include()}/terraform.tfstate"
    encrypt                = true
    skip_bucket_versioning = false
    dynamodb_table         = "terraform-locks"
  }
}
