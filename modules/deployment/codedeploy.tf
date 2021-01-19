resource "aws_codedeploy_app" "this" {
  name             = var.function_name
  compute_platform = "Lambda"
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name               = var.function_name
  deployment_config_name = var.deployment_config_name
  deployment_group_name  = var.alias_name
  service_role_arn       = aws_iam_role.codedeploy.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
}
