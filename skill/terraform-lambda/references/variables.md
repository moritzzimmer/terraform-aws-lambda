# Variables Quick Reference

All variables for the terraform-aws-lambda module (v8.6.0). Use this as a lookup when adding features to an existing Lambda configuration.

## Required

| Variable | Type | Description |
|----------|------|-------------|
| `function_name` | `string` | A unique name for the Lambda function |

## Core Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `architectures` | `list(string)` | `null` | Instruction set: `["x86_64"]` or `["arm64"]` |
| `description` | `string` | `""` | What the function does |
| `handler` | `string` | `""` | Function entrypoint (auto-null for container images) |
| `runtime` | `string` | `""` | Runtime identifier (auto-null for container images) |
| `memory_size` | `number` | `128` | Memory in MB (128-10240). CPU scales linearly. |
| `timeout` | `number` | `3` | Max execution time in seconds (0-900). Capped at 5 for Lambda@Edge. |
| `ephemeral_storage_size` | `number` | `512` | /tmp storage in MB (512-10240) |
| `reserved_concurrent_executions` | `number` | `-1` | Concurrency limit. -1=unlimited, 0=disabled. |
| `publish` | `bool` | `false` | Publish as new version. Auto-true if snap_start or lambda_at_edge. |
| `layers` | `list(string)` | `[]` | Layer ARNs (max 5) |
| `tags` | `map(string)` | `{}` | Resource tags |

## Packaging

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `package_type` | `string` | `"Zip"` | `"Zip"` or `"Image"` |
| `filename` | `string` | `null` | Local zip path (conflicts with s3_*/image_uri) |
| `s3_bucket` | `string` | `null` | S3 bucket for deployment package |
| `s3_key` | `string` | `null` | S3 key for deployment package |
| `s3_object_version` | `string` | `null` | S3 object version |
| `image_uri` | `string` | `null` | ECR image URI |
| `source_code_hash` | `string` | `""` | Base64-SHA256 of the zip file (triggers redeploy on change) |
| `image_config` | `any` | `{}` | Container overrides: `entry_point`, `command`, `working_directory` |

## Environment & Secrets

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment` | `object({variables = map(string)})` | `null` | Environment variables |
| `kms_key_arn` | `string` | `""` | KMS key ARN to encrypt env vars at rest |
| `ssm` | `object({parameter_names = list(string)})` | `null` | SSM parameter access. Use exact names, no wildcards. |

## Networking

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_config` | `object({security_group_ids, subnet_ids, ipv6_allowed_for_dual_stack})` | `null` | VPC attachment |
| `file_system_config` | `object({arn, local_mount_path})` | `null` | EFS mount. Requires VPC. Path must start with `/mnt/`. |
| `replace_security_groups_on_destroy` | `bool` | `null` | Replace SGs before destroy |
| `replacement_security_group_ids` | `list(string)` | `null` | Replacement SGs for destroy |

## Observability

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tracing_config_mode` | `string` | `null` | X-Ray: `"PassThrough"` or `"Active"` |
| `cloudwatch_lambda_insights_enabled` | `bool` | `false` | Lambda Insights metrics |
| `cloudwatch_logs_enabled` | `bool` | `true` | CloudWatch Logs IAM permissions |
| `create_cloudwatch_log_group` | `bool` | `true` | Manage log group via Terraform |
| `cloudwatch_logs_retention_in_days` | `number` | `null` | Retention: 1,3,5,7,14,30,60,90,120,150,180,365,400,545,731,1827,3653,0 |
| `cloudwatch_logs_kms_key_id` | `string` | `null` | KMS key for log encryption |
| `cloudwatch_logs_log_group_class` | `string` | `null` | `"STANDARD"`, `"INFREQUENT_ACCESS"`, `"DELIVERY"` |
| `cloudwatch_logs_skip_destroy` | `bool` | `false` | Keep logs on destroy |
| `logging_config` | `object({log_format, application_log_level, log_group, system_log_level})` | `null` | Advanced logging. `log_format`: `"JSON"` or `"Text"`. |

## Event Sources

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `event_source_mappings` | `any` | `{}` | SQS, Kinesis, DynamoDB stream mappings |
| `sns_subscriptions` | `map(any)` | `{}` | SNS topic subscriptions |
| `cloudwatch_event_rules` | `map(any)` | `{}` | EventBridge rules (scheduled + event pattern) |
| `cloudwatch_log_subscription_filters` | `map(any)` | `{}` | Log subscription filters |

## Deployment

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ignore_external_function_updates` | `bool` | `false` | Set true for CodeDeploy/external deployment tools |

## Special Features

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `lambda_at_edge` | `bool` | `false` | Lambda@Edge (Node.js/Python only). Forces timeout <= 5s. |
| `snap_start` | `bool` | `false` | Java Snap Start. Requires x86_64, Java 11+. |

## IAM

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `iam_role_name` | `string` | `null` | Override role name (default: `{function_name}-{region}`, max 64 chars) |
| `region` | `string` | `null` | Override region for IAM naming |
