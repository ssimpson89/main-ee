#!/bin/bash

# Build script for AWX Execution Environment
set -e

# Show help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [RUNTIME] [TAG]"
    echo ""
    echo "Arguments:"
    echo "  RUNTIME  Container runtime: 'podman' (default) or 'docker'"
    echo "  TAG      Image tag (default: ghcr.io/ctrliq/ascender-ee:latest)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Build with podman"
    echo "  $0 docker                           # Build with docker"
    echo "  $0 podman my-custom-tag:latest     # Build with custom tag"
    exit 0
fi

RUNTIME=${1:-podman}
TAG=${2:-ghcr.io/ctrliq/ascender-ee:latest}

echo "Building with $RUNTIME..."

# Clean up existing image
if [ "$RUNTIME" = "docker" ]; then
    docker rmi "$TAG" 2>/dev/null || true
    ansible-builder build -v3 -t "$TAG" --container-runtime=docker
else
    podman rmi "$TAG" 2>/dev/null || true
    ansible-builder build -v3 -t "$TAG"
fi

echo "Build completed: $TAG"
