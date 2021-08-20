data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

provider "aws" {
  region = "eu-west-1"
}
