locals {
  environment   = "production"
  function_name = "with-ecr-codepipeline"
}

module "lambda" {
  source     = "../../../"
  depends_on = [null_resource.initial_image]

  description                      = "Example usage for a containerized AWS Lambda deployed using CodePipeline and CodeDeploy."
  function_name                    = local.function_name
  ignore_external_function_updates = true
  image_uri                        = "${aws_ecr_repository.this.repository_url}:${local.environment}"
  package_type                     = "Image"
  publish                          = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Deployment resources
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lambda_alias" "this" {
  function_name    = module.lambda.function_name
  function_version = module.lambda.version
  name             = local.environment

  lifecycle {
    ignore_changes = [function_version]
  }
}

module "deployment" {
  source = "../../../modules/deployment"

  alias_name          = aws_lambda_alias.this.name
  ecr_image_tag       = local.environment
  ecr_repository_name = aws_ecr_repository.this.name
  function_name       = local.function_name
}

resource "aws_ecr_repository" "this" {
  name = local.function_name
}

// this resource is only used for the initial `terraform apply` - all further
// deployments are running on CodePipeline
resource "null_resource" "initial_image" {
  depends_on = [aws_ecr_repository.this]

  provisioner "local-exec" {
    command     = "docker build --tag ${aws_ecr_repository.this.repository_url}:${local.environment} ."
    working_dir = "${path.module}/../../fixtures/context"
  }

  provisioner "local-exec" {
    command     = "docker push --all-tags ${aws_ecr_repository.this.repository_url}"
    working_dir = "${path.module}/../../fixtures/context"
  }
}
