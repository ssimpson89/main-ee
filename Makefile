.PHONY: help build build-docker build-podman build-2.16 build-2.20 build-all clean install

# Default values
RUNTIME ?= podman
TAG ?= ghcr.io/ssimpson89/main-ee:latest
ANSIBLE_VERSION ?= 2.20

help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*##/ { printf "  %-15s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install: ## Install ansible-builder
	pip install 'git+https://github.com/ansible/ansible-builder.git@devel#egg=ansible-builder'

build: ## Build execution environment (default: podman, ansible 2.20)
	@echo "Building with $(RUNTIME) using Ansible $(ANSIBLE_VERSION)..."
	@$(RUNTIME) rmi $(TAG) 2>/dev/null || true
	@if [ "$(ANSIBLE_VERSION)" = "2.16" ]; then \
		EE_FILE="execution-environment-2.16.yml"; \
	else \
		EE_FILE="execution-environment-2.20.yml"; \
	fi; \
	if [ "$(RUNTIME)" = "docker" ]; then \
		ansible-builder build -v3 -t $(TAG) --container-runtime=docker -f $$EE_FILE; \
	else \
		ansible-builder build -v3 -t $(TAG) -f $$EE_FILE; \
	fi

build-podman: ## Build with podman
	@$(MAKE) build RUNTIME=podman

build-docker: ## Build with docker
	@$(MAKE) build RUNTIME=docker

build-2.16: ## Build Ansible 2.16 version
	@$(MAKE) build ANSIBLE_VERSION=2.16 TAG=ghcr.io/ssimpson89/main-ee:latest-2.16

build-2.20: ## Build Ansible 2.20 version
	@$(MAKE) build ANSIBLE_VERSION=2.20 TAG=ghcr.io/ssimpson89/main-ee:latest

build-all: ## Build both Ansible 2.16 and 2.20 versions
	@$(MAKE) build-2.16
	@$(MAKE) build-2.20

clean: ## Remove built images
	@echo "Cleaning up images..."
	@podman rmi ghcr.io/ssimpson89/main-ee:latest 2>/dev/null || true
	@podman rmi ghcr.io/ssimpson89/main-ee:latest-2.16 2>/dev/null || true
	@docker rmi ghcr.io/ssimpson89/main-ee:latest 2>/dev/null || true
	@docker rmi ghcr.io/ssimpson89/main-ee:latest-2.16 2>/dev/null || true
