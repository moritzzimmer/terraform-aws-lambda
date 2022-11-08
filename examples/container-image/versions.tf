terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.9"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2"
    }
  }
}