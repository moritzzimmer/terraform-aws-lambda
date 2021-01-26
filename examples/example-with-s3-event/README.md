
Skip to content
Pull requests
Issues
Marketplace
Explore
@moritzzimmer
moritzzimmer /
terraform-aws-lambda

3
11

    8

Code
Issues 3
Pull requests 1
Actions
Projects
Security
Insights

    Settings

terraform-aws-lambda/examples/example-with-s3-event/

1

# Example with S3 event

2

​

3

Creates an AWS Lambda function triggered by a S3 [event](https://docs.aws.amazon.com/lambda/latest/dg/with-s3.html).

4

​

5

## requirements

6

​

7

- [Terraform 0.12+](https://www.terraform.io/)

8

- authentication configuration for the [aws provider](https://www.terraform.io/docs/providers/aws/)

9

​

10

## usage

11

​

12

```

13

terraform init

14

terraform plan

15

```

16

​

17

## bootstrap with func

18

​

19

In case you are using [go](https://golang.org/) for developing your Lambda functions, you can also use [func](https://github.com/moritzzimmer/func) to bootstrap your project and get started quickly:

20

​

21

```

22

$ func new example-with-s3 -e s3

23

$ cd example-with-s3 && make init package plan

24

```

25

​

@moritzzimmer
Commit changes
Commit summary
Optional extended description
Commit directly to the master branch.
Create a new branch for this commit and start a pull request. Learn more about pull requests.

    © 2021 GitHub, Inc.
    Terms
    Privacy
    Security
    Status
    Help

    Contact GitHub
    Pricing
    API
    Training
    Blog
    About

