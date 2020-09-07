## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.0 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| description | Description of what your Lambda Function does. | `string` | `""` | no |
| environment | Environment (e.g. env variables) configuration for the Lambda function enable you to dynamically pass settings to your function code and libraries | <pre>object({<br>    variables = map(string)<br>  })</pre> | `null` | no |
| event | Event source configuration which triggers the Lambda function. Supported events: cloudwatch-scheduled-event, dynamodb, s3, sns | `map(string)` | `{}` | no |
| filename | The path to the function's deployment package within the local filesystem. If defined, The s3\_-prefixed options cannot be used. | `string` | `""` | no |
| function\_name | A unique name for your Lambda Function. | `any` | n/a | yes |
| handler | The function entrypoint in your code. | `any` | n/a | yes |
| kms\_key\_arn | Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables. If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key. If this configuration is provided when environment variables are not in use, the AWS Lambda API does not save this configuration and Terraform will show a perpetual difference of adding the key. To fix the perpetual difference, remove this configuration. | `string` | `""` | no |
| layers | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function. | `list(string)` | `[]` | no |
| log\_retention\_in\_days | Specifies the number of days you want to retain log events in the specified log group. Defaults to 14. | `number` | `14` | no |
| logfilter\_destination\_arn | The ARN of the destination to deliver matching log events to. Kinesis stream or Lambda function ARN. | `string` | `""` | no |
| memory\_size | Amount of memory in MB your Lambda Function can use at runtime. Defaults to 128. | `number` | `128` | no |
| publish | Whether to publish creation/change as new Lambda Function Version. Defaults to false. | `bool` | `false` | no |
| reserved\_concurrent\_executions | The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1. | `string` | `"-1"` | no |
| runtime | The runtime environment for the Lambda function you are uploading. | `any` | n/a | yes |
| s3\_bucket | The S3 bucket location containing the function's deployment package. Conflicts with filename. This bucket must reside in the same AWS region where you are creating the Lambda function. | `string` | `""` | no |
| s3\_key | The S3 key of an object containing the function's deployment package. Conflicts with filename. | `string` | `""` | no |
| s3\_object\_version | The object version containing the function's deployment package. Conflicts with filename. | `string` | `""` | no |
| source\_code\_hash | Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3\_key. The usual way to set this is filebase64sha256('file.zip') where 'file.zip' is the local filename of the lambda function source archive. | `string` | `""` | no |
| ssm | List of AWS Systems Manager Parameter Store parameter names. The IAM role of this Lambda function will be enhanced with read permissions for those parameters. Parameters must start with a forward slash and can be encrypted with the default KMS key. | <pre>object({<br>    parameter_names = list(string)<br>  })</pre> | `null` | no |
| ssm\_parameter\_names | DEPRECATED: use `ssm` object instead. This variable will be removed in version 6 of this module. (List of AWS Systems Manager Parameter Store parameters this Lambda will have access to. In order to decrypt secure parameters, a kms\_key\_arn needs to be provided as well.) | `list` | `[]` | no |
| tags | A mapping of tags to assign to the Lambda function and all resources supporting tags. | `map(string)` | `{}` | no |
| timeout | The amount of time your Lambda Function has to run in seconds. Defaults to 3. | `number` | `3` | no |
| vpc\_config | Provide this to allow your function to access your VPC (if both 'subnet\_ids' and 'security\_group\_ids' are empty then vpc\_config is considered to be empty or unset, see https://docs.aws.amazon.com/lambda/latest/dg/vpc.html for details). | <pre>object({<br>    security_group_ids = list(string)<br>    subnet_ids         = list(string)<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| function\_name | The unique name of your Lambda Function. |
| invoke\_arn | The ARN to be used for invoking Lambda Function from API Gateway - to be used in aws\_api\_gateway\_integration's uri |
| role\_name | The name of the IAM role attached to the Lambda Function. |
| version | Latest published version of your Lambda Function. |

