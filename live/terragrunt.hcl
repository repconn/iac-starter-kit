locals {
  # automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl", "fallback.hcl"))
  aws_profile = local.account_vars.locals.aws_profile
  aws_profile_fallback = local.aws_profile == "" ? "default" : local.aws_profile
  gcp_project = local.account_vars.locals.gcp_project
  gcp_project_fallback = local.gcp_project == "" ? "acme" : local.gcp_project

  # automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl", "fallback.hcl"))
  aws_region = local.region_vars.locals.aws_region
  aws_region_fallback = local.aws_region == "" ? "us-east-1" : local.aws_region
  gcp_region = local.region_vars.locals.gcp_region
  gcp_region_fallback = local.gcp_region == "" ? "us-west1" : local.gcp_region

  # automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl", "fallback.hcl"))
  env = local.environment_vars.locals.environment

  name = "iac-terraform"
}

terraform {
  # Create cache dir to store downloaded modules and dependencies
  before_hook "before_cache" {
    commands = [get_terraform_command()]
    execute = ["mkdir", "-p", abspath("${get_parent_terragrunt_dir()}../_cache")]
  }

  # Tell Terraform to use cache directory
  extra_arguments "cache" {
    commands = [get_terraform_command()]
    env_vars = {
      TF_PLUGIN_CACHE_DIR = abspath("${get_parent_terragrunt_dir()}/../_cache")
    }
  }

  # Perform "init" before "plan" every time
  before_hook "before_hook" {
    commands = ["plan"]
    execute = ["terraform", "init"]
  }
}

generate "versions" {
  path = "_versions.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<-EOF
    terraform {
      required_version = "1.2.4"

      required_providers {
        aws = {
          source = "hashicorp/aws"
          version = "~> 3.0"
        }
        google = {
          source = "hashicorp/google"
          version = "4.27.0"
        }
      }
    }
  EOF
}

generate "providers" {
  path = "_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<-EOF
    provider "aws" {
      region = "${local.aws_region_fallback}"
      profile = "${local.aws_profile_fallback}"
      insecure = false
      default_tags = {
        Terraform = true
      }
      # skip credentials validation via the STS API
      skip_credentials_validation = true
      # skip validating the region
      skip_region_validation = true
      # skip the AWS Metadata API check
      skip_metadata_api_check = true
      # skip getting the supported EC2 platforms
      skip_get_ec2_platforms = true

    }
    provider "google" {
      region = "${local.gcp_region_fallback}"
      project = "${local.gcp_project_fallback}"
    }
  EOF
}

// # Configure Terragrunt to automatically store tfstate files in an S3 bucket
// remote_state {
//   backend = "s3"

//   generate = {
//     path = "backend.tf"
//     if_exists = "overwrite_terragrunt"
//   }
//   config = {
//     encrypt = true
//     bucket = "${local.name}-state"
//     key = "${path_relative_to_include()/terraform.tfstate}"
//     region = local.aws_region_fallback
//     skip_buclet_versioning = false
//     profile = local.aws_profile_fallback
//     dynamodb_table = "${local.name}-locks"
//   }
// }

