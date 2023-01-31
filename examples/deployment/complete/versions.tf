terraform {
  required_version = ">= 0.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.51"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2"
    }
  }
}