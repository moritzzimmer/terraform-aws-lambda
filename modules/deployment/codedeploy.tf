resource "aws_codedeploy_app" "this" {
  region = var.region

  name             = var.function_name
  compute_platform = "Lambda"
}

resource "aws_codedeploy_deployment_group" "this" {
  region = var.region

  app_name               = var.function_name
  deployment_config_name = var.deployment_config_name
  deployment_group_name  = var.alias_name
  service_role_arn       = aws_iam_role.codedeploy.arn

  dynamic "alarm_configuration" {
    for_each = var.codedeploy_deployment_group_alarm_configuration_enabled ? [true] : []
    content {
      alarms                    = var.codedeploy_deployment_group_alarm_configuration_alarms
      enabled                   = var.codedeploy_deployment_group_alarm_configuration_enabled
      ignore_poll_alarm_failure = var.codedeploy_deployment_group_alarm_configuration_ignore_poll_alarm_failure
    }
  }

  dynamic "auto_rollback_configuration" {
    for_each = var.codedeploy_deployment_group_auto_rollback_configuration_enabled ? [true] : []
    content {
      enabled = var.codedeploy_deployment_group_auto_rollback_configuration_enabled
      events  = var.codedeploy_deployment_group_auto_rollback_configuration_events
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
}
