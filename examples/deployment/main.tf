data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ecr_authorization_token" "token" {}

locals {
  environment   = "production"
  function_name = "example-with-code-pipeline"
}

provider "aws" {
  region = "eu-west-1"
}

provider "docker" {
  registry_auth {
    address  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    password = data.aws_ecr_authorization_token.token.password
    username = data.aws_ecr_authorization_token.token.user_name
  }
}

resource "aws_lambda_alias" "example" {
  function_name    = module.lambda.function_name
  function_version = module.lambda.version
  name             = local.environment
}

module "deployment" {
  source = "../../modules/deployment"

  alias_name    = aws_lambda_alias.example.name
  function_name = local.function_name
}

module "lambda" {
  source        = "../../"
  description   = "Example usage for an AWS Lambda deployed using CodePipeline."
  function_name = local.function_name
  image_uri     = docker_registry_image.image.name
  package_type  = "Image"

  image_config = {
    // optionally overwrite arguments like 'command'
    // from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#image_config
    command = ["app.handler"]
  }
}

resource "docker_registry_image" "image" {
  name = "${module.deployment.ecr_repository_url}:${local.environment}"

  build {
    context = "context"
  }
}