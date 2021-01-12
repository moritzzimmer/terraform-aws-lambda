# Example with SQS event source mappings

Creates an AWS Lambda function triggered by SQS [event source mappings](https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html).

## Usage

To run this example execute:

```
$ terraform init
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` to destroy those resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.0 |
| aws | >= 3.19 |

## Providers

| Name | Version |
|------|---------|
| archive | n/a |
| aws | >= 3.19 |

## Inputs

No input.

## Outputs

| Name | Description |
|------|-------------|
| arn | The Amazon Resource Name (ARN) identifying your Lambda Function. |
| event\_source\_arns | The Amazon Resource Names (ARNs) identifying the event sources. |
| function\_name | The unique name of your Lambda Function. |
| role\_name | The name of the IAM role attached to the Lambda Function. |
