# Runtime Reference

Complete handler code, build tooling, and Terraform config for each supported Lambda runtime.

## Table of Contents
- [Go](#go)
- [Python](#python)
- [Java](#java)
- [.NET](#dotnet)
- [Node.js](#nodejs)
- [Rust](#rust)
- [Container Images](#container-images)

---

## Go

**Runtime:** `provided.al2023` (custom runtime)
**Handler:** `bootstrap`
**Architecture:** `arm64` (default)

### Handler (main.go)

```go
package main

import (
	"context"
	"github.com/aws/aws-lambda-go/lambda"
)

type request struct {
	// Define your input structure
}

type response struct {
	StatusCode int    `json:"statusCode"`
	Body       string `json:"body"`
}

func handler(ctx context.Context, event request) (*response, error) {
	return &response{
		StatusCode: 200,
		Body:       "Hello from Go Lambda!",
	}, nil
}

func main() {
	lambda.Start(handler)
}
```

### Build config (go.mod)

```
module github.com/<org>/<function-name>

go 1.24

require github.com/aws/aws-lambda-go v1.47.0
```

Run `go mod tidy` after creating.

### Makefile targets

```makefile
build: ## Compile Go binary for Lambda
	GOOS=linux GOARCH=arm64 go build -tags lambda.norpc -o build/bootstrap main.go

package: build ## Package as zip
	cd build && zip lambda.zip bootstrap

clean: ## Remove build artifacts
	rm -rf build
```

### Terraform module block

```hcl
architectures    = ["arm64"]
filename         = "${path.module}/../build/lambda.zip"
handler          = "bootstrap"
memory_size      = 128
runtime          = "provided.al2023"
source_code_hash = fileexists("${path.module}/../build/lambda.zip") ? filebase64sha256("${path.module}/../build/lambda.zip") : null
```

**Notes:**
- Go uses `provided.al2023` custom runtime — the binary IS the runtime
- Binary must be named `bootstrap` for custom runtimes
- `-tags lambda.norpc` reduces binary size by disabling the deprecated RPC mode
- `GOARCH=arm64` matches the `architectures = ["arm64"]` setting

---

## Python

**Runtime:** `python3.13` (or latest available: `python3.14` in preview)
**Handler:** `app.main.handler` (module path format: `package.module.function`)
**Architecture:** `arm64` (default)

### Handler (app/main.py)

```python
from aws_lambda_powertools import Logger

logger = Logger()


@logger.inject_lambda_context
def handler(event, context):
    logger.info("Processing event", extra={"event": event})

    return {
        "statusCode": 200,
        "body": "Hello from Python Lambda!"
    }
```

### Build config (pyproject.toml)

```toml
[project]
name = "<function-name>"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = [
    "aws-lambda-powertools>=3.0.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

### Makefile targets

```makefile
lock: ## Lock dependencies
	uv lock

package: lock ## Package Lambda function with dependencies
	uv export --frozen --no-dev --no-editable -o build/requirements.txt
	uv pip install \
		--no-installer-metadata \
		--no-compile-bytecode \
		--python-platform aarch64-manylinux2014 \
		--python-version 3.13 \
		--target build/packages \
		-r build/requirements.txt
	cd build/packages && zip -r ../lambda.zip .
	cd .. && zip -r build/lambda.zip app

clean: ## Remove build artifacts
	rm -rf build
```

### Terraform module block

```hcl
architectures    = ["arm64"]
filename         = "${path.module}/../build/lambda.zip"
handler          = "app.main.handler"
memory_size      = 256
runtime          = "python3.13"
source_code_hash = fileexists("${path.module}/../build/lambda.zip") ? filebase64sha256("${path.module}/../build/lambda.zip") : null
```

**Notes:**
- Uses `uv` for fast, deterministic dependency resolution
- `--python-platform aarch64-manylinux2014` cross-compiles native deps for Lambda's AL2023 arm64
- Dependencies go at zip root, app source in `app/` — handler path reflects this: `app.main.handler`
- aws-lambda-powertools provides structured logging, tracing integration, and event parsing
- If the user prefers `pip` over `uv`, adapt the Makefile accordingly

---

## Java

**Runtime:** `java21` (LTS) or `java25`
**Handler:** `example.Handler::handleRequest` (format: `package.ClassName::methodName`)
**Architecture:** `arm64` (default), use `x86_64` if enabling snap_start

### Handler (src/main/java/example/Handler.java)

```java
package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import java.util.HashMap;
import java.util.Map;

public class Handler implements RequestHandler<Map<String, Object>, Map<String, Object>> {

    @Override
    public Map<String, Object> handleRequest(Map<String, Object> input, Context context) {
        context.getLogger().log("Processing request");

        Map<String, Object> response = new HashMap<>();
        response.put("statusCode", 200);
        response.put("body", "Hello from Java Lambda!");
        return response;
    }
}
```

### Build config

**settings.gradle:**
```gradle
rootProject.name = '<function-name>'
```

**build.gradle:**
```gradle
plugins {
    id 'java'
}

java {
    sourceCompatibility = JavaVersion.toVersion(21)
    targetCompatibility = JavaVersion.toVersion(21)
}

repositories {
    mavenCentral()
}

dependencies {
    compileOnly 'com.amazonaws:aws-lambda-java-core:1.2.3'
}

tasks.register('buildZip', Zip) {
    from compileJava
    from processResources
    into('lib') {
        from configurations.runtimeClasspath
    }
    archiveFileName = 'lambda.zip'
    destinationDirectory = layout.buildDirectory.dir('distributions')
}
```

### Makefile targets

```makefile
build: ## Compile Java source
	./gradlew build

package: ## Package as zip with dependencies
	./gradlew buildZip

clean: ## Remove build artifacts
	./gradlew clean
	rm -f build/distributions/lambda.zip
```

### Terraform module block

```hcl
architectures    = ["arm64"]
filename         = "${path.module}/../build/distributions/lambda.zip"
handler          = "example.Handler::handleRequest"
memory_size      = 512
runtime          = "java21"
source_code_hash = fileexists("${path.module}/../build/distributions/lambda.zip") ? filebase64sha256("${path.module}/../build/distributions/lambda.zip") : null
```

**With Snap Start (faster cold starts):**
```hcl
architectures    = ["x86_64"]
snap_start       = true
memory_size      = 512
runtime          = "java21"
```

**Notes:**
- Java Lambdas benefit from higher `memory_size` (512+) — CPU scales linearly with memory
- Snap Start requires `x86_64` and Java 11+ — dramatically reduces cold start time
- The `buildZip` Gradle task places compiled classes at root and dependencies in `lib/`
- Gradle wrapper (`gradlew`) should be committed to the repo

---

## .NET

**Runtime:** `dotnet8` (LTS) or `dotnet10`
**Handler:** `AssemblyName::Namespace.ClassName::MethodName`
**Architecture:** `arm64` (default)

### Handler (Function.cs)

```csharp
using Amazon.Lambda.Core;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace MyFunction;

public class Function
{
    public object FunctionHandler(object input, ILambdaContext context)
    {
        context.Logger.LogInformation("Processing request");

        return new
        {
            statusCode = 200,
            body = "Hello from .NET Lambda!"
        };
    }
}
```

### Build config (MyFunction.csproj)

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <GenerateRuntimeConfigurationFiles>true</GenerateRuntimeConfigurationFiles>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Amazon.Lambda.Core" Version="2.8.0" />
    <PackageReference Include="Amazon.Lambda.Serialization.SystemTextJson" Version="2.4.5" />
  </ItemGroup>
</Project>
```

### Makefile targets

```makefile
build: ## Build .NET project
	dotnet publish -c Release -o build/publish

package: build ## Package as zip
	cd build/publish && zip -r ../lambda.zip .

clean: ## Remove build artifacts
	dotnet clean
	rm -rf build bin obj
```

### Terraform module block

```hcl
architectures    = ["arm64"]
filename         = "${path.module}/../build/lambda.zip"
handler          = "MyFunction::MyFunction.Function::FunctionHandler"
memory_size      = 256
runtime          = "dotnet8"
source_code_hash = fileexists("${path.module}/../build/lambda.zip") ? filebase64sha256("${path.module}/../build/lambda.zip") : null
```

**Notes:**
- Handler format: `AssemblyName::Namespace.ClassName::MethodName`
- Assembly name comes from the `.csproj` filename (without extension)
- `GenerateRuntimeConfigurationFiles` must be true for Lambda to find the entry point
- The entire `publish` output directory gets zipped (includes all DLLs and config)

---

## Node.js

**Runtime:** `nodejs22.x` (latest), `nodejs20.x` (LTS)
**Handler:** `index.handler` (format: `filename.exportedFunction`)
**Architecture:** `arm64` (default)

### Handler (src/index.mjs)

```javascript
export const handler = async (event, context) => {
  console.log("Processing event:", JSON.stringify(event));

  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Hello from Node.js Lambda!" }),
  };
};
```

### Build config (package.json)

```json
{
  "name": "<function-name>",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "build": "esbuild src/index.mjs --bundle --platform=node --target=node22 --outfile=build/index.mjs --format=esm --external:@aws-sdk/*"
  },
  "devDependencies": {
    "esbuild": "^0.24.0"
  }
}
```

### Makefile targets

```makefile
build: ## Bundle with esbuild
	npm ci
	npm run build

package: build ## Package as zip
	cd build && zip lambda.zip index.mjs

clean: ## Remove build artifacts
	rm -rf build node_modules
```

### Terraform module block

```hcl
architectures    = ["arm64"]
filename         = "${path.module}/../build/lambda.zip"
handler          = "index.handler"
memory_size      = 128
runtime          = "nodejs22.x"
source_code_hash = fileexists("${path.module}/../build/lambda.zip") ? filebase64sha256("${path.module}/../build/lambda.zip") : null
```

**Notes:**
- esbuild bundles everything into a single file — fast, tree-shakes unused code
- `--external:@aws-sdk/*` excludes the AWS SDK (already available in Lambda runtime)
- For simple functions with no dependencies, skip esbuild and zip the source directly
- Use `.mjs` extension with `"type": "module"` for ES modules

---

## Rust

**Runtime:** `provided.al2023` (custom runtime)
**Handler:** `bootstrap`
**Architecture:** `arm64` (default)

### Handler (src/main.rs)

```rust
use lambda_runtime::{service_fn, Error, LambdaEvent};
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
struct Request {
    // Define your input structure
}

#[derive(Serialize)]
struct Response {
    status_code: i32,
    body: String,
}

async fn handler(_event: LambdaEvent<Request>) -> Result<Response, Error> {
    Ok(Response {
        status_code: 200,
        body: "Hello from Rust Lambda!".to_string(),
    })
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    lambda_runtime::run(service_fn(handler)).await
}
```

### Build config (Cargo.toml)

```toml
[package]
name = "<function-name>"
version = "0.1.0"
edition = "2024"

[dependencies]
lambda_runtime = "0.13"
serde = { version = "1", features = ["derive"] }
tokio = { version = "1", features = ["macros"] }
```

### Makefile targets

Requires [cargo-lambda](https://www.cargo-lambda.info/):

```makefile
build: ## Build for Lambda with cargo-lambda
	cargo lambda build --release --arm64 --output-format zip

package: build ## Copy zip to expected location
	mkdir -p build
	cp target/lambda/<function-name>/bootstrap.zip build/lambda.zip

clean: ## Remove build artifacts
	cargo clean
	rm -rf build
```

### Terraform module block

```hcl
architectures    = ["arm64"]
filename         = "${path.module}/../build/lambda.zip"
handler          = "bootstrap"
memory_size      = 128
runtime          = "provided.al2023"
source_code_hash = fileexists("${path.module}/../build/lambda.zip") ? filebase64sha256("${path.module}/../build/lambda.zip") : null
```

**Notes:**
- Rust uses `provided.al2023` custom runtime, same as Go — the compiled binary is the runtime
- `cargo-lambda` handles cross-compilation and produces a correctly structured zip
- Binary must be named `bootstrap`
- Rust Lambdas have near-zero cold starts and minimal memory usage

---

## Container Images

**Package type:** `Image`
**No handler/runtime in Terraform** — configured in Dockerfile

### Dockerfile

```dockerfile
FROM public.ecr.aws/lambda/python:3.13

COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install -r requirements.txt

COPY app/ ${LAMBDA_TASK_ROOT}/app/

CMD ["app.main.handler"]
```

Base images available for all runtimes: `public.ecr.aws/lambda/<runtime>:<version>`

### Terraform module block

```hcl
package_type = "Image"
image_uri    = "${aws_ecr_repository.this.repository_url}:latest"

# Optional: override Dockerfile CMD/ENTRYPOINT
image_config = {
  command           = ["app.main.handler"]
  entry_point       = ["/lambda-entrypoint.sh"]
  working_directory = "/var/task"
}
```

### ECR setup (add to Terraform)

```hcl
resource "aws_ecr_repository" "this" {
  name                 = var.function_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

### Build and push (Makefile)

```makefile
REPO_URL := $(shell terraform -chdir=terraform output -raw ecr_repository_url)

build: ## Build container image
	docker build --platform linux/arm64 -t $(REPO_URL):latest .

push: build ## Push to ECR
	aws ecr get-login-password | docker login --username AWS --password-stdin $(REPO_URL)
	docker push $(REPO_URL):latest

clean: ## Remove local images
	docker rmi $(REPO_URL):latest 2>/dev/null || true
```

**Notes:**
- When `package_type = "Image"`, the module automatically sets `handler` and `runtime` to null
- `image_config` is optional — only use it to override the Dockerfile's CMD/ENTRYPOINT
- Build with `--platform linux/arm64` to match `architectures = ["arm64"]`
- Use immutable tags in production — `:latest` shown here for simplicity
- For S3 packaging, use `s3_bucket`, `s3_key`, and optionally `s3_object_version` instead of `filename`
