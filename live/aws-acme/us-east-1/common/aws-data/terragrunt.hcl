# This is example of minimal terragrunt configuration file
# Feel free to copy and modify it
terraform {
  source = "${get_parent_terragrunt_dir()}/..//modules/aws_data"
}

include {
  path = find_in_parent_folders()
}

inputs = {}
