output "role_name" {
  value       = aws_iam_role.github_actions.name
  description = "The name of the IAM role created"
}
