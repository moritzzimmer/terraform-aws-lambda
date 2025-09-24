variable "github_repository" {
  description = "Name of the GitHub repository that will run the action, including repository owner (e.g. moritzzimmer/terraform-aws-lambda)"
  type        = string
  nullable    = false
  validation {
    condition     = length(split("/", var.github_repository)) == 2
    error_message = "Repository must be of format $owner/$repository_name"
  }
}

variable "github_refs" {
  description = "Name of the refs (e.g. branches) on which the action will run."
  type        = list(string)
  default     = ["main"]
  nullable    = false
}

variable "role_name" {
  description = "Name of the IAM role to create. If not set github-actions-$github_repository-$region will be used"
  type        = string
  default     = null
  nullable    = true
}

variable "s3_prefixes" {
  description = "(Optional) S3 prefixes (bucket name + key) that the role can write/read to/from. E.g. ci-eu-central-1/foo. If not set, no S3 access will be granted."
  type        = list(string)
  default     = null
  nullable    = true
}

variable "ecr_repositories" {
  description = "(Optional) ECR repository names that the role can push to. If not set, no ECR access will be granted."
  type        = list(string)
  default     = null
  nullable    = true
}
