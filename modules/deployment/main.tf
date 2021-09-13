data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  artifact_store_bucket     = var.codepipeline_artifact_store_bucket != "" ? var.codepipeline_artifact_store_bucket : aws_s3_bucket.pipeline[0].bucket
  artifact_store_bucket_arn = "arn:aws:s3:::${local.artifact_store_bucket}"
}

resource "aws_codepipeline" "this" {
  name     = var.function_name
  role_arn = var.codepipeline_role_arn == "" ? aws_iam_role.codepipeline_role[0].arn : var.codepipeline_role_arn
  tags     = var.tags

  artifact_store {
    location = local.artifact_store_bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    dynamic "action" {
      for_each = var.ecr_repository_name != "" ? [true] : []
      content {
        name             = "ECR"
        category         = "Source"
        owner            = "AWS"
        provider         = "ECR"
        version          = "1"
        namespace        = "SourceVariables"
        input_artifacts  = []
        output_artifacts = ["source"]

        configuration = {
          "ImageTag" : var.ecr_image_tag,
          "RepositoryName" : var.ecr_repository_name
        }
      }
    }

    dynamic "action" {
      for_each = var.s3_bucket != "" ? [true] : []
      content {
        name             = "S3"
        category         = "Source"
        owner            = "AWS"
        provider         = "S3"
        version          = "1"
        namespace        = "SourceVariables"
        input_artifacts  = []
        output_artifacts = ["source"]

        configuration = {
          S3Bucket : var.s3_bucket,
          S3ObjectKey : var.s3_key,
          PollForSourceChanges : "false"
        }
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "CodeBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = []

      configuration = {
        ProjectName : aws_codebuild_project.this.name
        EnvironmentVariables = jsonencode([
          {
            name  = "SOURCEVARIABLES_VERSIONID"
            value = var.s3_bucket != "" ? "#{SourceVariables.VersionId}" : ""
            type  = "PLAINTEXT"
          },
          {
            name  = "SOURCEVARIABLES_IMAGE_URI"
            value = var.ecr_repository_name != "" ? "#{SourceVariables.ImageURI}" : ""
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }
}

resource "aws_s3_bucket" "pipeline" {
  count = var.codepipeline_artifact_store_bucket == "" ? 1 : 0

  acl           = "private"
  bucket        = "${var.function_name}-pipeline-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "source" {
  count = var.codepipeline_artifact_store_bucket == "" ? 1 : 0

  bucket                  = aws_s3_bucket.pipeline[count.index].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
