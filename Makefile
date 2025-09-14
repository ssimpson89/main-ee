.PHONY: help build build-docker build-podman clean install

# Default values
RUNTIME ?= podman
TAG ?= ghcr.io/ctrliq/ascender-ee:latest

help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*##/ { printf "  %-15s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install: ## Install ansible-builder
	pip install 'git+https://github.com/ansible/ansible-builder.git@devel#egg=ansible-builder'

build: ## Build execution environment (default: podman)
	@echo "Building with $(RUNTIME)..."
	@$(RUNTIME) rmi $(TAG) 2>/dev/null || true
	@if [ "$(RUNTIME)" = "docker" ]; then \
		ansible-builder build -v3 -t $(TAG) --container-runtime=docker; \
	else \
		ansible-builder build -v3 -t $(TAG); \
	fi

build-podman: ## Build with podman
	@$(MAKE) build RUNTIME=podman

build-docker: ## Build with docker
	@$(MAKE) build RUNTIME=docker

clean: ## Remove built images
	@echo "Cleaning up images..."
	@podman rmi $(TAG) 2>/dev/null || true
	@docker rmi $(TAG) 2>/dev/null || true
