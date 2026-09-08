.PHONY: help install create build build-all clean

RUNTIME         ?= podman
ANSIBLE_VERSION ?= 2.20
IMAGE           ?= ghcr.io/ssimpson89/main-ee
ANSIBLE_BUILDER_VERSION ?= 3.1.1

SUPPORTED_VERSIONS = 2.20 2.16

# The tag suffix is data, not a conditional. 2.20 is the default variant and
# gets the bare tag; everything else is suffixed with its version.
TAG_SUFFIX_2.20 =
TAG_SUFFIX_2.16 = -2.16

EE_FILE = execution-environment-$(ANSIBLE_VERSION).yml
TAG    ?= $(IMAGE):latest$(TAG_SUFFIX_$(ANSIBLE_VERSION))

ifeq ($(filter $(ANSIBLE_VERSION),$(SUPPORTED_VERSIONS)),)
  $(error Unsupported ANSIBLE_VERSION '$(ANSIBLE_VERSION)'. Supported: $(SUPPORTED_VERSIONS))
endif

help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_.-]+:.*##/ { printf "  %-12s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "Variables:"
	@echo "  RUNTIME=$(RUNTIME) (podman|docker)"
	@echo "  ANSIBLE_VERSION=$(ANSIBLE_VERSION) ($(SUPPORTED_VERSIONS))"
	@echo "  TAG=$(TAG)"

install: ## Install ansible-builder at the version CI uses
	pip install "ansible-builder==$(ANSIBLE_BUILDER_VERSION)"

create: ## Generate the build context and Containerfile without building
	ansible-builder create -v3 -f $(EE_FILE) -c context

build: ## Build one variant (ANSIBLE_VERSION=2.20|2.16)
	@echo "Building $(TAG) from $(EE_FILE) with $(RUNTIME)"
	ansible-builder build -v3 -t $(TAG) --container-runtime=$(RUNTIME) -f $(EE_FILE)

build-all: ## Build every supported variant
	@for v in $(SUPPORTED_VERSIONS); do $(MAKE) --no-print-directory build ANSIBLE_VERSION=$$v || exit 1; done

clean: ## Remove locally built images and the generated context
	@for v in $(SUPPORTED_VERSIONS); do \
		$(MAKE) --no-print-directory -s _rmi ANSIBLE_VERSION=$$v; \
	done
	@rm -rf context

_rmi:
	@$(RUNTIME) rmi $(TAG) 2>/dev/null || true
