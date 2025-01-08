data "aws_availability_zones" "available" {}

locals {
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "fixtures" {
  source = "../fixtures"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  azs                          = local.azs
  cidr                         = local.vpc_cidr
  enable_ipv6                  = true
  name                         = module.fixtures.output_function_name
  private_subnets              = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnet_ipv6_prefixes = [3, 4, 5]
}

module "lambda" {
  source = "../../"

  architectures                      = ["arm64"]
  description                        = "Example AWS Lambda function inside a VPC."
  ephemeral_storage_size             = 512
  filename                           = module.fixtures.output_path
  function_name                      = module.fixtures.output_function_name
  handler                            = "index.handler"
  memory_size                        = 128
  replace_security_groups_on_destroy = true
  runtime                            = "nodejs22.x"
  publish                            = false
  snap_start                         = false
  source_code_hash                   = module.fixtures.output_base64sha256
  timeout                            = 3

  vpc_config = {
    ipv6_allowed_for_dual_stack = true
    security_group_ids          = [module.vpc.default_security_group_id]
    subnet_ids                  = module.vpc.private_subnets
  }
}