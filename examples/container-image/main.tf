data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ecr_authorization_token" "token" {}

locals {
  ecr           = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
  function_name = "example-with-container-images"
}

provider "aws" {
  region = "eu-west-1"
}

provider "docker" {
  registry_auth {
    address  = local.ecr
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
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
    command = ["app.handler"]
  }
}

resource "docker_registry_image" "image" {
  name = "${local.ecr}/${aws_ecr_repository.this.id}:latest"

  build {
    context = "context"
  }
}