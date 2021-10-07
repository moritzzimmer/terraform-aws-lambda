config {
  module = true
}

plugin "aws" {
  enabled = true
  version = "0.7.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
