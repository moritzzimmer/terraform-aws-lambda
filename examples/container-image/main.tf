provider "aws" {
  region = "eu-west-1"
}

provider "docker" {
  registry_auth {
    address  = local.ecr_address
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ecr_authorization_token" "token" {}

locals {
  ecr_address   = format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.current.account_id, data.aws_region.current.name)
  ecr_image     = format("%v/%v:%v", local.ecr_address, aws_ecr_repository.this.id, "1.0")
  function_name = "example-with-container-images"
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
  name = local.ecr_image

  build {
    context = "context"
  }
}