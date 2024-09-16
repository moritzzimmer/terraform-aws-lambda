# Example with Kinesis event source mappings

Creates an AWS Lambda function triggered by Kinesis [event source mappings](https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html).

## Usage

To run this example execute:

```
$ terraform init
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` to destroy those resources.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.32 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.2 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.32 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lambda"></a> [lambda](#module\_lambda) | ../../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_kinesis_stream.stream_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_stream) | resource |
| [aws_kinesis_stream.stream_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_stream) | resource |
| [aws_kinesis_stream_consumer.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_stream_consumer) | resource |
| [archive_file.kinesis_handler](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"eu-west-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| <a name="output_event_source_arns"></a> [event\_source\_arns](#output\_event\_source\_arns) | The Amazon Resource Names (ARNs) identifying the event sources. |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | The unique name of your Lambda Function. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the IAM role attached to the Lambda Function. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->