data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
