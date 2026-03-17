# Runtime Reference

Each runtime has specific Terraform settings and project layout conventions.
All runtimes default to `arm64` architecture (Graviton — better price/performance).

Use the **latest stable Lambda runtime** for each language. Don't hardcode
specific versions in this reference — check what AWS currently supports.

## Makefile conventions

All projects use a Makefile with these conventions:

- `MODE ?= plan` variable — `make tf` runs plan, `make tf MODE=apply` deploys
- `terraform -chdir=terraform init` + `terraform -chdir=terraform $(MODE)`
- Standard targets: `help`, `build` (compile), `package` (zip), `tf` (deploy), `clean`
- Help target uses grep to auto-document targets from `## comments`

```makefile
# This help target pattern is used by all runtimes:
help: ## Display this help screen
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
```

The `tf` target is always the same across runtimes:
```makefile
tf: package ## Run terraform init and MODE (default: plan)
	terraform -chdir=terraform init
	terraform -chdir=terraform $(MODE)
```

## Table of Contents

- [Go](#go)
- [Python](#python)
- [Java](#java)
- [.NET](#net)
- [Node.js](#nodejs)
- [Container Image](#container-image)

---

## Go

**Terraform settings:**
```hcl
architectures    = ["arm64"]
handler          = "bootstrap"
memory_size      = 128
runtime          = "provided.al2023"
timeout          = 30
```

Go uses `provided.al2023` (custom runtime) because AWS doesn't have a managed
Go runtime. The handler is always `bootstrap`.

**Project layout** — idiomatic Go, source at project root:
```
<function-name>/
├── main.go
├── go.mod
├── Makefile
└── terraform/
```

**Build approach:**
- Cross-compile: `GOOS=linux GOARCH=arm64 go build -tags lambda.norpc -o build/bootstrap main.go`
- Package: `cd build && zip lambda.zip bootstrap`
- After generation, run `go mod tidy` to resolve dependencies

**Key dependency:** `github.com/aws/aws-lambda-go`

---

## Python

**Terraform settings:**
```hcl
architectures    = ["arm64"]
handler          = "app.main.handler"
memory_size      = 256
runtime          = "<latest python runtime>"
timeout          = 30
```

**Project layout** — source in `app/` directory (not `src/`), `pyproject.toml`
at root:
```
<function-name>/
├── app/
│   ├── __init__.py
│   └── main.py
├── pyproject.toml
├── Makefile
└── terraform/
```

**Build approach — uses `uv` (not pip):**
- `uv lock` to create/update lock file
- `uv export --frozen --no-dev --no-editable` to generate requirements.txt
- `uv pip install` with `--python-platform aarch64-manylinux2014` for ARM cross-compilation
- Zip dependencies from `build/packages/`, then add `app/` directory

Generate a `pyproject.toml` with the project name, Python version constraint,
and empty dependencies list. Run `uv lock` after generation.

---

## Java

**Terraform settings:**
```hcl
architectures    = ["arm64"]
handler          = "<package>.Handler::handleRequest"
memory_size      = 512
runtime          = "<latest java runtime>"
timeout          = 30
```

If the user wants fast cold starts, suggest `snap_start = true`.

**Project layout** — Gradle project at root, standard Java source layout:
```
<function-name>/
├── build.gradle
├── settings.gradle
├── gradlew / gradlew.bat / gradle/
├── src/main/java/<package-path>/Handler.java
├── Makefile
└── terraform/
```

**Build approach:**
- `./gradlew build` to compile
- `./gradlew buildZip` to create deployment zip
- Makefile `build` and `package` targets delegate to Gradle

**Key conventions for `build.gradle`:**
- Use `compileOnly` (not `implementation`) for `aws-lambda-java-core` — it's
  provided at runtime by Lambda
- Use the Gradle lazy task API (`tasks.register`) — required by modern Gradle
- Use `layout.buildDirectory` — `$buildDir` is deprecated
- Create a `buildZip` task of type `Zip` that packages compiled classes +
  runtime dependencies into `build/distributions/lambda.zip`

Also generate `settings.gradle` and the Gradle wrapper (`gradle wrapper`).

---

## .NET

**Terraform settings:**
```hcl
architectures    = ["arm64"]
handler          = "<Namespace>::<Namespace>.Function::FunctionHandler"
memory_size      = 256
runtime          = "<latest dotnet runtime>"
timeout          = 30
```

**Project layout** — source at project root (not in `src/`):
```
<function-name>/
├── Function.cs
├── <ProjectName>.csproj
├── Makefile
└── terraform/
```

**Build approach:**
- `dotnet publish -c Release -o build/publish`
- `cd build/publish && zip -r ../lambda.zip .`
- Clean: `dotnet clean` + `rm -rf build bin obj`

**Key NuGet packages:** `Amazon.Lambda.Core` and
`Amazon.Lambda.Serialization.SystemTextJson`

---

## Node.js

**Terraform settings:**
```hcl
architectures    = ["arm64"]
handler          = "index.handler"
memory_size      = 128
runtime          = "<latest nodejs runtime>"
timeout          = 30
```

Node.js is the simplest case — for basic functions without dependencies, no
Makefile is strictly needed (just zip the source).

For projects with dependencies, generate a Makefile that runs `npm ci --omit=dev`
and zips the result.

---

## Container Image

**Terraform settings:**
```hcl
image_uri    = "<account-id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>"
package_type = "Image"
memory_size  = 256
timeout      = 30
```

No `runtime`, `handler`, `filename`, or `source_code_hash` when using container
images. The user provides a Dockerfile and ECR repository.

Generate a Makefile with `package` (docker build), `push` (ECR login + push),
and `tf` (push + terraform) targets. Use `--platform linux/arm64` for the
docker build.
