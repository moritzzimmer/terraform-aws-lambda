data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_s3_bucket" "artefacts" {
  bucket = var.s3_bucket
}

resource "aws_codepipeline" "this" {
  name     = var.function_name
  role_arn = var.codepipeline_role_arn == "" ? aws_iam_role.codepipeline_role[0].arn : var.codepipeline_role_arn
  tags     = var.tags

  artifact_store {
    location = var.s3_bucket
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
