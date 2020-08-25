VERSION := $(shell cat VERSION.txt)
PREFIX?=$(shell pwd)
EXAMPLES_DIR := examples

## Tools
BINDIR := $(PREFIX)/bin
export GOBIN :=$(BINDIR)
export PATH := $(GOBIN):$(PATH)
SEMBUMP := $(BINDIR)/sembump

all: init fmt validate

.PHONY: init
init: ## Initialize a Terraform working directory
	@echo "+ $@"
	@terraform init

.PHONY: fmt
fmt: ## Rewrites config files to canonical format
	@echo "+ $@"
	@terraform fmt -check=true -recursive

.PHONY: validate
validate: ## Validates the Terraform files
	@echo "+ $@"
	@AWS_REGION=eu-west-1 terraform validate

.PHONY: test
test: ## Validates and generates execution plan for all examples.
	@echo "+ $@"
	@for dir in `ls $(EXAMPLES_DIR)`; do \
		echo "--> $$dir"; \
		terraform init $(PREFIX)/$(EXAMPLES_DIR)/$$dir/ > /dev/null; \
		terraform validate $(PREFIX)/$(EXAMPLES_DIR)/$$dir/; \
		terraform plan $(PREFIX)/$(EXAMPLES_DIR)/$$dir/ > /dev/null; \
		rm -rf $(PREFIX)/$(EXAMPLES_DIR)/$$dir/.terraform; \
	done

.PHONY: documentation
documentation: ## Generates README.md from static snippets and Terraform variables
	terraform-docs markdown table . > docs/part2.md
	cat docs/*.md > README.md

.PHONY: tag
tag: ## Create a new git tag to prepare to build a release
	git tag -a $(VERSION) -m "$(VERSION)"
	@echo "Run git push origin $(VERSION) to push your new tag to GitHub and trigger a build."

$(SEMBUMP):
	GO111MODULE=off go get -u github.com/jessfraz/junk/sembump

.PHONY: bump-version
BUMP := patch
bump-version: $(SEMBUMP) ## Bump the version in the version file. Set BUMP to [ patch | major | minor ].
	@echo "+ $@"
	$(eval NEW_VERSION = $(shell $(BINDIR)/sembump --kind $(BUMP) $(VERSION)))
	@echo "Bumping VERSION.txt from $(VERSION) to $(NEW_VERSION)"
	echo $(NEW_VERSION) > VERSION.txt
	@echo "Updating links in README.md"
	sed -i '' s/$(subst v,,$(VERSION))/$(subst v,,$(NEW_VERSION))/g docs/part1.md

.PHONY: check-git-clean
check-git-clean:
	@echo "+ $@"
	@git diff-index --quiet HEAD || (echo "There are uncomitted changes"; exit 1)

.PHONY: check-git-branch
check-git-branch: check-git-clean
	@echo "+ $@"
	git fetch --all --tags --prune
	git checkout master

release: check-git-branch bump documentation ## Releases a new module version
	@echo "+ $@"
	git add VERSION.txt README.md docs/part1.md
	git commit -vsam "Bump version to $(NEW_VERSION)"
	@echo "Run make tag to create and push the tag for new version $(NEW_VERSION)"

.PHONY: help
help: ## Display this help screen
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
