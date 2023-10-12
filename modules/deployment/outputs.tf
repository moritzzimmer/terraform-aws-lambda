output "codebuild_project_arn" {
  description = "The Amazon Resource Name (ARN) of the CodeBuild project."
  value       = aws_codebuild_project.this.arn
}

output "codebuild_project_id" {
  description = "The Id of the CodeBuild project."
  value       = aws_codebuild_project.this.id
}

output "codedeploy_app_arn" {
  description = "The Amazon Resource Name (ARN) of the CodeDeploy application."
  value       = aws_codedeploy_app.this.arn
}

output "codedeploy_app_name" {
  description = "The name of the CodeDeploy application."
  value       = aws_codedeploy_app.this.name
}

output "codedeploy_deployment_group_arn" {
  description = "The Amazon Resource Name (ARN) of the CodeDeploy deployment group."
  value       = aws_codedeploy_deployment_group.this.arn
}

output "codedeploy_deployment_group_deployment_group_id" {
  description = "The ID of the CodeDeploy deployment group."
  value       = aws_codedeploy_deployment_group.this.deployment_group_id
}

output "codedeploy_deployment_group_id" {
  description = "Application name and deployment group name."
  value       = aws_codedeploy_deployment_group.this.id
}

output "codepipeline_arn" {
  description = "The Amazon Resource Name (ARN) of the CodePipeline."
  value       = aws_codepipeline.this.arn
}

output "codepipeline_artifact_storage_arn" {
  description = "The Amazon Resource Name (ARN) of the CodePipeline artifact store."
  value       = "${local.artifact_store_bucket_arn}/${local.pipeline_artifacts_folder}"
}

output "codepipeline_id" {
  description = "The ID of the CodePipeline."
  value       = aws_codepipeline.this.id
}

output "codepipeline_role_name" {
  description = "The name of the IAM role used for the CodePipeline."
  value       = try(aws_iam_role.codepipeline_role[0].name, "")
}
