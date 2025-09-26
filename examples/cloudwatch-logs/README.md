# Example with CloudWatch logs configuration

Create AWS Lambda functions showcasing [advanced logging configuration](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-cloudwatchlogs-loggroups.html)
and log [subscription filters](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Subscriptions.html).

## usage

```
terraform init
terraform plan
terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` to destroy those resources.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.2 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_fixtures"></a> [fixtures](#module\_fixtures) | ../fixtures | n/a |
| <a name="module_logs_subscription"></a> [logs\_subscription](#module\_logs\_subscription) | ../../ | n/a |
| <a name="module_sub_1"></a> [sub\_1](#module\_sub\_1) | ../../ | n/a |
| <a name="module_sub_2"></a> [sub\_2](#module\_sub\_2) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [archive_file.subscription_handler](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"eu-west-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| <a name="output_cloudwatch_custom_log_group_arn"></a> [cloudwatch\_custom\_log\_group\_arn](#output\_cloudwatch\_custom\_log\_group\_arn) | The Amazon Resource Name (ARN) identifying the custom CloudWatch log group used by your Lambda function. |
| <a name="output_cloudwatch_custom_log_group_name"></a> [cloudwatch\_custom\_log\_group\_name](#output\_cloudwatch\_custom\_log\_group\_name) | The name of the custom CloudWatch log group. |
| <a name="output_cloudwatch_existing_log_group_arn"></a> [cloudwatch\_existing\_log\_group\_arn](#output\_cloudwatch\_existing\_log\_group\_arn) | The Amazon Resource Name (ARN) identifying the existing CloudWatch log group used by your Lambda function. |
| <a name="output_cloudwatch_existing_log_group_name"></a> [cloudwatch\_existing\_log\_group\_name](#output\_cloudwatch\_existing\_log\_group\_name) | The name of the existing CloudWatch log group. |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | The unique name of your Lambda Function. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the IAM role attached to the Lambda Function. |
<!-- END_TF_DOCS -->