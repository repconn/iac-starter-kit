# This module standardizes the output of existing AWS resources

data "aws_vpc" "default" {
  default = true
}

output "default_vpc_id" {
  value = data.aws_vpc.default.id
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

output "default_subnet_ids" {
  value = data.aws_subnet_ids.default.ids
}
