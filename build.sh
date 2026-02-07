#!/bin/bash

# Build script for AWX Execution Environment
set -e

# Show help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [RUNTIME] [TAG] [ANSIBLE_VERSION]"
    echo ""
    echo "Arguments:"
    echo "  RUNTIME          Container runtime: 'podman' (default) or 'docker'"
    echo "  TAG              Image tag (default: ghcr.io/ssimpson89/main-ee:latest)"
    echo "  ANSIBLE_VERSION  Ansible version: '2.16' or '2.20' (default: 2.20)"
    echo ""
    echo "Examples:"
    echo "  $0                                                   # Build with podman, ansible 2.20"
    echo "  $0 docker                                            # Build with docker, ansible 2.20"
    echo "  $0 podman ghcr.io/ssimpson89/main-ee:latest-2.16 2.16  # Build ansible 2.16"
    echo "  $0 podman ghcr.io/ssimpson89/main-ee:latest 2.20       # Build ansible 2.20"
    exit 0
fi

RUNTIME=${1:-podman}
TAG=${2:-ghcr.io/ssimpson89/main-ee:latest}
ANSIBLE_VERSION=${3:-2.20}

# Determine which execution environment file to use
if [[ "$ANSIBLE_VERSION" == "2.16" ]]; then
    EE_FILE="execution-environment-2.16.yml"
elif [[ "$ANSIBLE_VERSION" == "2.20" ]]; then
    EE_FILE="execution-environment-2.20.yml"
else
    echo "Error: Unsupported Ansible version '$ANSIBLE_VERSION'. Supported versions: 2.16, 2.20"
    exit 1
fi

echo "Building with $RUNTIME using $EE_FILE..."

# Clean up existing image
if [ "$RUNTIME" = "docker" ]; then
    docker rmi "$TAG" 2>/dev/null || true
    ansible-builder build -v3 -t "$TAG" --container-runtime=docker -f "$EE_FILE"
else
    podman rmi "$TAG" 2>/dev/null || true
    ansible-builder build -v3 -t "$TAG" -f "$EE_FILE"
fi

echo "Build completed: $TAG (Ansible $ANSIBLE_VERSION)"
