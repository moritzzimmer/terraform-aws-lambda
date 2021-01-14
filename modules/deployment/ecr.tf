resource "aws_ecr_repository" "this" {
  name = var.function_name
  tags = var.tags

  image_scanning_configuration {
    scan_on_push = true
  }
}
