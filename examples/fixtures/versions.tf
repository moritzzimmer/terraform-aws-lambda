terraform {
  required_version = ">= 0.12.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2"
    }
  }
}
