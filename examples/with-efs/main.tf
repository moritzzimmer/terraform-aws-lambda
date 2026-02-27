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

  azs             = local.azs
  cidr            = local.vpc_cidr
  name            = module.fixtures.output_function_name
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
}

resource "aws_security_group" "efs" {
  name   = "${module.fixtures.output_function_name}-efs"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.vpc.default_security_group_id]
  }
}

resource "aws_efs_file_system" "this" {
  creation_token = module.fixtures.output_function_name
  encrypted      = true

  tags = {
    Name = module.fixtures.output_function_name
  }
}

resource "aws_efs_mount_target" "this" {
  count = length(module.vpc.private_subnets)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/lambda"

    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}

module "lambda" {
  source = "../../"

  architectures    = ["arm64"]
  description      = "Example AWS Lambda function with EFS file system."
  filename         = module.fixtures.output_path
  function_name    = module.fixtures.output_function_name
  handler          = "index.handler"
  memory_size      = 128
  runtime          = "nodejs22.x"
  publish          = false
  snap_start       = false
  source_code_hash = module.fixtures.output_base64sha256
  timeout          = 30

  file_system_config = {
    arn              = aws_efs_access_point.this.arn
    local_mount_path = "/mnt/efs"
  }

  vpc_config = {
    security_group_ids = [module.vpc.default_security_group_id]
    subnet_ids         = module.vpc.private_subnets
  }

  // EFS mount targets must be in available state before Lambda can use them
  depends_on = [aws_efs_mount_target.this]
}
