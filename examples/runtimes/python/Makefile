MODE ?= plan

.PHONY: help lock package tf clean

help: ## Display this help screen
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

lock: ## Create or update the uv.lock file
	uv lock

package: ## Create the Lambda deployment zip
	uv export --frozen --no-dev --no-editable -o build/requirements.txt
	uv pip install \
		--no-installer-metadata \
		--no-compile-bytecode \
		--python-platform aarch64-manylinux2014 \
		--python-version 3.14 \
		--target build/packages \
		-r build/requirements.txt
	cd build/packages && zip -r ../lambda.zip .
	cd build && zip -r lambda.zip -j ../handler.py

tf: package ## Run terraform init and MODE (default: plan)
	terraform -chdir=terraform init
	terraform -chdir=terraform $(MODE)

clean: ## Remove build artifacts
	rm -rf build
