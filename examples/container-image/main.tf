module "fixtures" {
  source = "../fixtures"
}

locals {
  environment   = "production"
  function_name = module.fixtures.output_function_name
}

#trivy:ignore:AVD-AWS-0031
resource "aws_ecr_repository" "this" {
  force_delete = true
  name         = local.function_name

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "lambda" {
  source     = "../../"
  depends_on = [null_resource.initial_image]

  description   = "Example usage for an AWS Lambda using container images."
  function_name = local.function_name
  image_uri     = "${aws_ecr_repository.this.repository_url}:${local.environment}"
  package_type  = "Image"
}

resource "null_resource" "initial_image" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.this.repository_url}"
  }

  provisioner "local-exec" {
    command     = "docker build --tag ${aws_ecr_repository.this.repository_url}:${local.environment} ."
    working_dir = "${path.module}/../fixtures/context"
  }

  provisioner "local-exec" {
    command     = "docker push --all-tags ${aws_ecr_repository.this.repository_url}"
    working_dir = "${path.module}/../fixtures/context"
  }
}
