.PHONY: help install create build build-2.16 build-2.20 build-all clean

RUNTIME         ?= podman
ANSIBLE_VERSION ?= 2.20
IMAGE           ?= ghcr.io/ssimpson89/main-ee
ANSIBLE_BUILDER_VERSION ?= 3.1.1

SUPPORTED_VERSIONS = 2.16 2.20

# 2.20 is the default variant, so it lives in the unsuffixed file and gets
# the unsuffixed tag. Everything else is suffixed with its version.
ifeq ($(ANSIBLE_VERSION),2.20)
  EE_FILE    = execution-environment.yml
  TAG_SUFFIX =
else
  EE_FILE    = execution-environment-$(ANSIBLE_VERSION).yml
  TAG_SUFFIX = -$(ANSIBLE_VERSION)
endif

TAG ?= $(IMAGE):latest$(TAG_SUFFIX)

help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_.-]+:.*##/ { printf "  %-14s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "Variables:"
	@echo "  RUNTIME=$(RUNTIME) (podman|docker)"
	@echo "  ANSIBLE_VERSION=$(ANSIBLE_VERSION) ($(SUPPORTED_VERSIONS))"
	@echo "  TAG=$(TAG)"

install: ## Install ansible-builder at the version CI uses
	pip install "ansible-builder==$(ANSIBLE_BUILDER_VERSION)"

check-version:
	@if ! echo "$(SUPPORTED_VERSIONS)" | grep -qw "$(ANSIBLE_VERSION)"; then \
		echo "Unsupported ANSIBLE_VERSION '$(ANSIBLE_VERSION)'. Supported: $(SUPPORTED_VERSIONS)"; \
		exit 1; \
	fi

create: check-version ## Generate the build context without building
	ansible-builder create -v3 -f $(EE_FILE) -c context

build: check-version ## Build one variant (ANSIBLE_VERSION=2.16|2.20)
	@echo "Building $(TAG) from $(EE_FILE) with $(RUNTIME)"
	ansible-builder build -v3 -t $(TAG) --container-runtime=$(RUNTIME) -f $(EE_FILE)

build-2.20: ## Build the default variant (ansible-core 2.20, Rocky 10)
	@$(MAKE) build ANSIBLE_VERSION=2.20

build-2.16: ## Build the legacy variant (ansible-core 2.16, Rocky 9, EL8 targets)
	@$(MAKE) build ANSIBLE_VERSION=2.16

build-all: build-2.20 build-2.16 ## Build both variants

clean: ## Remove locally built images and the generated context
	@for v in $(SUPPORTED_VERSIONS); do \
		if [ "$$v" = "2.20" ]; then t="$(IMAGE):latest"; else t="$(IMAGE):latest-$$v"; fi; \
		$(RUNTIME) rmi "$$t" 2>/dev/null || true; \
	done
	@rm -rf context
