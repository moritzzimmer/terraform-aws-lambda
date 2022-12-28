output "codedeploy_deployment_group_arn" {
  description = "The Amazon Resource Name (ARN) of the CodeDeploy deployment group."
  value       = aws_codedeploy_deployment_group.this.arn
}