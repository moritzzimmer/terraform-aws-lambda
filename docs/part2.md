## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.0 |
| aws | >= 3.19 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.19 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| event-cloudwatch | ./modules/event/cloudwatch-event |  |
| event-dynamodb | ./modules/event/dynamodb |  |
| event-kinesis | ./modules/event/kinesis |  |
| event-s3 | ./modules/event/s3 |  |
| event-sns | ./modules/event/sns |  |
| event-sqs | ./modules/event/sqs |  |
| lambda | ./modules/lambda |  |

## Resources

| Name |
|------|
| [aws_caller_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) |
| [aws_cloudwatch_event_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) |
| [aws_cloudwatch_event_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) |
| [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) |
| [aws_cloudwatch_log_subscription_filter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) |
| [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) |
| [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| [aws_lambda_event_source_mapping](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) |
| [aws_lambda_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) |
| [aws_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) |
| [aws_sns_topic_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudwatch\_event\_rules | Creates EventBridge (CloudWatch Events) rules invoking your Lambda function. Required Lambda invocation permissions will be generated. | `map(any)` | `{}` | no |
| cloudwatch\_lambda\_insights\_enabled | Enable CloudWatch Lambda Insights for your Lambda function. | `bool` | `false` | no |
| cloudwatch\_lambda\_insights\_extension\_version | Version of the Lambda Insights extension for Lambda functions using `zip` deployment packages, see https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-extension-versions.html. | `number` | `14` | no |
| description | Description of what your Lambda Function does. | `string` | `""` | no |
| environment | Environment (e.g. env variables) configuration for the Lambda function enable you to dynamically pass settings to your function code and libraries | <pre>object({<br>    variables = map(string)<br>  })</pre> | `null` | no |
| event | (deprecated - use `cloudwatch_event_rules` [EventBridge/CloudWatch Events], `event_source_mappings` [DynamoDb, Kinesis, SQS] or `sns_subscriptions` [SNS] instead) Event source configuration which triggers the Lambda function. Supported events: cloudwatch-scheduled-event, dynamodb, kinesis, s3, sns, sqs | `map(string)` | `{}` | no |
| event\_source\_mappings | Creates event source mappings to allow the Lambda function to get events from Kinesis, DynamoDB and SQS. The IAM role of this Lambda function will be enhanced with necessary minimum permissions to get those events. | `map(any)` | `{}` | no |
| filename | The path to the function's deployment package within the local filesystem. If defined, The s3\_-prefixed options and image\_uri cannot be used. | `string` | `null` | no |
| function\_name | A unique name for your Lambda Function. | `string` | n/a | yes |
| handler | The function entrypoint in your code. | `string` | `""` | no |
| ignore\_external\_function\_updates | Ignore updates to your Lambda function executed externally to the Terraform lifecycle. Set this to `true` if you're using CodeDeploy, aws CLI or other external tools to update your Lambda function code. | `bool` | `false` | no |
| image\_config | The Lambda OCI [image configurations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#image_config) block with three (optional) arguments:<br><br>  - *entry\_point* - The ENTRYPOINT for the docker image (type `list(string)`).<br>  - *command* - The CMD for the docker image (type `list(string)`).<br>  - *working\_directory* - The working directory for the docker image (type `string`). | `any` | `{}` | no |
| image\_uri | The ECR image URI containing the function's deployment package. Conflicts with filename, s3\_bucket, s3\_key, and s3\_object\_version. | `string` | `null` | no |
| kms\_key\_arn | Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables. If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key. If this configuration is provided when environment variables are not in use, the AWS Lambda API does not save this configuration and Terraform will show a perpetual difference of adding the key. To fix the perpetual difference, remove this configuration. | `string` | `""` | no |
| lambda\_at\_edge | Enable Lambda@Edge for your Node.js or Python functions. Required trust relationship and publishing of function versions will be configured. | `bool` | `false` | no |
| layers | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function. | `list(string)` | `[]` | no |
| log\_retention\_in\_days | Specifies the number of days you want to retain log events in the specified log group. | `number` | `14` | no |
| logfilter\_destination\_arn | The ARN of the destination to deliver matching log events to. Kinesis stream or Lambda function ARN. | `string` | `""` | no |
| memory\_size | Amount of memory in MB your Lambda Function can use at runtime. | `number` | `128` | no |
| package\_type | The Lambda deployment package type. Valid values are Zip and Image. | `string` | `"Zip"` | no |
| publish | Whether to publish creation/change as new Lambda Function Version. | `bool` | `false` | no |
| reserved\_concurrent\_executions | The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. | `string` | `"-1"` | no |
| runtime | The runtime environment for the Lambda function you are uploading. | `string` | `""` | no |
| s3\_bucket | The S3 bucket location containing the function's deployment package. Conflicts with filename and image\_uri. This bucket must reside in the same AWS region where you are creating the Lambda function. | `string` | `null` | no |
| s3\_key | The S3 key of an object containing the function's deployment package. Conflicts with filename and image\_uri. | `string` | `null` | no |
| s3\_object\_version | The object version containing the function's deployment package. Conflicts with filename and image\_uri. | `string` | `null` | no |
| sns\_subscriptions | Creates subscriptions to SNS topics which trigger your Lambda function. Required Lambda invocation permissions will be generated. | `map(any)` | `{}` | no |
| source\_code\_hash | Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3\_key. The usual way to set this is filebase64sha256('file.zip') where 'file.zip' is the local filename of the lambda function source archive. | `string` | `""` | no |
| ssm | List of AWS Systems Manager Parameter Store parameter names. The IAM role of this Lambda function will be enhanced with read permissions for those parameters. Parameters must start with a forward slash and can be encrypted with the default KMS key. | <pre>object({<br>    parameter_names = list(string)<br>  })</pre> | `null` | no |
| ssm\_parameter\_names | DEPRECATED: use `ssm` object instead. This variable will be removed in version 6 of this module. (List of AWS Systems Manager Parameter Store parameters this Lambda will have access to. In order to decrypt secure parameters, a kms\_key\_arn needs to be provided as well.) | `list` | `[]` | no |
| tags | A mapping of tags to assign to the Lambda function and all resources supporting tags. | `map(string)` | `{}` | no |
| timeout | The amount of time your Lambda Function has to run in seconds. | `number` | `3` | no |
| tracing\_config\_mode | Tracing config mode of the Lambda function. Can be either PassThrough or Active. | `string` | `null` | no |
| vpc\_config | Provide this to allow your function to access your VPC (if both 'subnet\_ids' and 'security\_group\_ids' are empty then vpc\_config is considered to be empty or unset, see https://docs.aws.amazon.com/lambda/latest/dg/vpc.html for details). | <pre>object({<br>    security_group_ids = list(string)<br>    subnet_ids         = list(string)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| cloudwatch\_log\_group\_name | The name of the CloudWatch log group used by your Lambda function. |
| function\_name | The unique name of your Lambda Function. |
| invoke\_arn | The ARN to be used for invoking Lambda Function from API Gateway - to be used in aws\_api\_gateway\_integration's uri |
| role\_name | The name of the IAM role attached to the Lambda Function. |
| version | Latest published version of your Lambda Function. |
