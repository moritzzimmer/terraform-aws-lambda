data "aws_ecr_authorization_token" "token" {}

locals {
  environment   = "production"
  function_name = "example-with-code-pipeline"
}

resource "aws_lambda_alias" "this" {
  function_name    = module.lambda.function_name
  function_version = module.lambda.version
  name             = local.environment

  lifecycle {
    ignore_changes = [function_version]
  }
}

resource "aws_ecr_repository" "this" {
  name = local.function_name
}

module "deployment" {
  source = "../../modules/deployment"

  alias_name          = aws_lambda_alias.this.name
  ecr_image_tag       = local.environment
  ecr_repository_name = aws_ecr_repository.this.name
  function_name       = local.function_name
}

module "lambda" {
  source                           = "../../"
  description                      = "Example usage for an AWS Lambda deployed using CodePipeline and CodeDeploy."
  function_name                    = local.function_name
  ignore_external_function_updates = true
  image_uri                        = docker_registry_image.image.name
  package_type                     = "Image"
  publish                          = true

  image_config = {
    // optionally overwrite arguments like 'command'
    // from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#image_config
    command = ["app.handler"]
  }
}

resource "docker_registry_image" "image" {
  name = "${aws_ecr_repository.this.repository_url}:${local.environment}"

  build {
    context = "../fixtures/context"
  }
}