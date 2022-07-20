# The root terragrunt.hcl configuration
#
locals {
  # automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl", "fallback.hcl"))
  aws_profile = local.account_vars.locals.aws_profile == "" ? "acme" : local.account_vars.locals.aws_profile
  gcp_project = local.account_vars.locals.gcp_project == "" ? "default" : local.account_vars.locals.gcp_project

  # automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl", "fallback.hcl"))
  aws_region = local.region_vars.locals.aws_region == "" ? "us-east-1" : local.region_vars.locals.aws_region
  gcp_region = local.region_vars.locals.gcp_region == "" ? "us-west1" : local.region_vars.locals.gcp_region

  # automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl", "fallback.hcl"))
  env              = local.environment_vars.locals.environment
}

# These variables apply to all configurations in this subfolder.
# These are automatically merged into the child `terragrunt.hcl` config
# via the include block. Configure root level variables that all resources
# can inherit. This is especially helpful with multi-account configs where
# terraform_remote_state data sources are placed directly into the modules.
inputs = merge(
  local.account_vars.locals,
  local.region_vars.locals,
  local.environment_vars.locals
)

generate "versions" {
  path      = "_versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = "~>1.2.2"

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
  path      = "_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"
      profile = "${local.aws_profile}"
      insecure = false
      default_tags {
        tags = {
          Terraform = true
        }
      }
      # make it faster by skipping some checks
      #skip_get_ec2_platforms = true
      #skip_metadata_api_check = true
      #skip_region_validation = true
      #skip_credentials_validation = true
    }
    provider "google" {
      region = "${local.gcp_region}"
      project = "${local.gcp_project}"
    }
  EOF
}

terraform {
  # Force Terraform to keep trying to acquire a lock for
  # up to 10 minutes
  extra_arguments "retry_lock" {
    commands = [
      "init",
      "apply",
      "refresh",
      "import",
      "plan",
      "taint",
      "untaint"
    ]

    arguments = [
      "-lock-timeout=10m"
    ]
  }

  # Create cache dir to store downloaded modules and dependencies
  before_hook "before_cache" {
    commands = [get_terraform_command()]
    execute  = ["mkdir", "-p", abspath("${get_parent_terragrunt_dir()}/../_cache")]
  }

  # Tell Terraform to use cache directory
  extra_arguments "cache" {
    commands = [get_terraform_command()]
    env_vars = {
      TF_PLUGIN_CACHE_DIR = abspath("${get_parent_terragrunt_dir()}/../_cache")
    }
  }

  # Execute "init" before "plan" every time
  before_hook "before_hook" {
    commands = ["plan"]
    execute  = ["terraform", "init"]
  }
}
