terraform {
  required_version = ">= 1.3"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}
