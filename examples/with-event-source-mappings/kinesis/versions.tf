terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.82.2"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2"
    }
  }
}
