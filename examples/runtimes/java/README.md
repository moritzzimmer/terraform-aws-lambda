# Java runtime example

Creates an AWS Lambda function from a Java project built with Gradle.

## Prerequisites

- Java 25+

## Usage

```shell
make tf MODE=apply
```

Run `make help` to see all available targets.

Note that this example may create resources which cost money. Run `make tf MODE=destroy` when you don't need these resources.
