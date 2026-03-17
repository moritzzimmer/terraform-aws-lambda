# Variable Reference

Complete reference for the `moritzzimmer/lambda/aws` module variables, grouped
by feature area. The module handles IAM automatically — the "IAM effect" column
shows what happens behind the scenes.

## Required

| Variable | Type | Description |
|----------|------|-------------|
| `function_name` | `string` | Unique name for the Lambda function |

Everything else is optional.

---

## Core Lambda Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `architectures` | `list(string)` | `null` | `["x86_64"]` or `["arm64"]` |
| `description` | `string` | `""` | What the function does |
| `handler` | `string` | `""` | Function entrypoint |
| `runtime` | `string` | `""` | Runtime identifier (e.g., `python3.14`, `provided.al2023`) |
| `package_type` | `string` | `"Zip"` | `Zip` or `Image` |
| `publish` | `bool` | `false` | Publish as new version on each change |
| `timeout` | `number` | `3` | Execution timeout in seconds |
| `memory_size` | `number` | `128` | Memory in MB |
| `ephemeral_storage_size` | `number` | `512` | /tmp storage in MB (512–10240) |
| `reserved_concurrent_executions` | `number` | `-1` | Concurrency limit (-1 = unlimited, 0 = disabled!) |
| `kms_key_arn` | `string` | `""` | KMS key for env var encryption |
| `tags` | `map(string)` | `{}` | Resource tags |

---

## Deployment Package

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `filename` | `string` | `null` | Local path to zip |
| `source_code_hash` | `string` | `""` | Base64-encoded SHA256 of zip |
| `s3_bucket` | `string` | `null` | S3 bucket for zip |
| `s3_key` | `string` | `null` | S3 key for zip |
| `s3_object_version` | `string` | `null` | S3 object version |
| `image_uri` | `string` | `null` | ECR image URI (for `package_type = "Image"`) |
| `image_config` | `map(any)` | `{}` | Container overrides: `entry_point`, `command`, `working_directory` |

---

## Environment

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment` | `object({variables = map(string)})` | `null` | Environment variables |
| `layers` | `list(string)` | `[]` | Lambda Layer ARNs (max 5) |

---

## VPC & Network

| Variable | Type | Default | IAM Effect |
|----------|------|---------|------------|
| `vpc_config` | `object({ipv6_allowed_for_dual_stack = optional(bool), security_group_ids = list(string), subnet_ids = list(string)})` | `null` | Attaches `AWSLambdaENIManagementAccess` |
| `replace_security_groups_on_destroy` | `bool` | `null` | — |
| `replacement_security_group_ids` | `list(string)` | `null` | — |

---

## EFS File System

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `file_system_config` | `object({arn = string, local_mount_path = string})` | `null` | EFS access point ARN + mount path (must start with `/mnt/`) |

Requires `vpc_config` to be set (EFS needs network access).

---

## CloudWatch Logs

| Variable | Type | Default | IAM Effect |
|----------|------|---------|------------|
| `cloudwatch_logs_enabled` | `bool` | `true` | Attaches `logs:CreateLogStream`, `logs:PutLogEvents` |
| `create_cloudwatch_log_group` | `bool` | `true` | — |
| `cloudwatch_logs_retention_in_days` | `number` | `null` | — |
| `cloudwatch_logs_log_group_class` | `string` | `null` | `STANDARD`, `INFREQUENT_ACCESS`, or `DELIVERY` |
| `cloudwatch_logs_kms_key_id` | `string` | `null` | — |
| `cloudwatch_logs_skip_destroy` | `bool` | `false` | — |
| `logging_config` | `object(...)` | `null` | Advanced: `log_format`, `application_log_level`, `system_log_level` |
| `cloudwatch_log_subscription_filters` | `map(any)` | `{}` | — |

---

## Event Sources

| Variable | Type | Default | IAM Effect |
|----------|------|---------|------------|
| `cloudwatch_event_rules` | `map(any)` | `{}` | Creates `lambda:InvokeFunction` permission for events.amazonaws.com |
| `sns_subscriptions` | `map(any)` | `{}` | Creates `lambda:InvokeFunction` permission for sns.amazonaws.com |
| `event_source_mappings` | `map(any)` | `{}` | Service-specific read permissions (SQS, DynamoDB, Kinesis) |

---

## Monitoring & Tracing

| Variable | Type | Default | IAM Effect |
|----------|------|---------|------------|
| `tracing_config_mode` | `string` | `null` | `Active` or `PassThrough`. Attaches `AWSXRayDaemonWriteAccess` |
| `cloudwatch_lambda_insights_enabled` | `bool` | `false` | Attaches `CloudWatchLambdaInsightsExecutionRolePolicy` |

---

## Advanced Features

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `lambda_at_edge` | `bool` | `false` | Lambda@Edge (Node.js/Python only, incompatible with VPC) |
| `snap_start` | `bool` | `false` | SnapStart for fast cold starts (Java only) |
| `ssm` | `object({parameter_names = list(string)})` | `null` | SSM parameter read access. IAM: `ssm:GetParameter(s)` |
| `ignore_external_function_updates` | `bool` | `false` | For CodeDeploy/CLI managed updates |

---

## Outputs

| Output | Description |
|--------|-------------|
| `arn` | Lambda function ARN |
| `function_name` | Lambda function name |
| `invoke_arn` | ARN for API Gateway integration |
| `role_name` | IAM role name |
| `role_arn` | IAM role ARN |
| `version` | Latest published version |
| `cloudwatch_log_group_name` | Log group name |
| `cloudwatch_log_group_arn` | Log group ARN |
