MODE ?= plan

.PHONY: help build package tf clean

help: ## Display this help screen
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build the .NET project
	dotnet publish -c Release -o build/publish

package: build ## Package the Lambda function as a zip
	cd build/publish && zip -r ../lambda.zip .

tf: package ## Run terraform init and MODE (default: plan)
	terraform -chdir=terraform init
	terraform -chdir=terraform $(MODE)

clean: ## Remove build artifacts
	dotnet clean
	rm -rf build bin obj
