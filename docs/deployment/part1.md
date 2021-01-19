# Lambda function deployments using AWS CodePipeline and AWS CodeDeploy

Terraform module to create AWS resources for blue/green deployments of [Lambda](https://www.terraform.io/docs/providers/aws/r/lambda_function.html) functions
using AWS [CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html) and [CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-steps-lambda.html)

<img src="../../docs/deployment/deployment.png" />

## Features

- fully automated AWS CodePipelines triggered by ECR pushes of containerized Lambda functions
- creation of IAM roles with permissions following the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege) for CodePipeline, CodeBuild and CodeDeploy
  or bring your own roles
- optional CodeStar notifications via SNS

(currently) not supported:

- S3 based deployments of Lambda functions
- `BeforeAllowTraffic` and `AfterAllowTraffic` hooks in CodeDeploy
- external configuration of CodeBuild infrastructure like `compute_type` or `image`

