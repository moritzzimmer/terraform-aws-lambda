data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ecr_authorization_token" "token" {}

locals {
  ecr           = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
  function_name = "example-with-container-images"
}

provider "docker" {
  registry_auth {
    address  = local.ecr
    password = data.aws_ecr_authorization_token.token.password
    username = data.aws_ecr_authorization_token.token.user_name
  }
}

resource "aws_ecr_repository" "this" {
  name = local.function_name
}

module "lambda" {
  source        = "../../"
  description   = "Example usage for an AWS Lambda using container images."
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
  name = "${aws_ecr_repository.this.repository_url}:latest"

  build {
    context = "../fixtures/context"
  }
}