# Dual Ansible Version Container Strategy

## Overview
This repository now builds two separate container images to support different Ansible versions:
- **Ansible 2.20** (Latest/Default) - For new deployments and modern infrastructure
- **Ansible 2.16** (Legacy) - For backward compatibility with older machines

## Container Tags

### Ansible 2.20 (Default)
- `ghcr.io/ssimpson89/main-ee:latest` - Always points to the latest 2.20 release
- `ghcr.io/ssimpson89/main-ee:{version}` - Specific version (e.g., `2026.02.1`)
- `ghcr.io/ssimpson89/main-ee:dev` - Development builds

### Ansible 2.16 (Legacy)
- `ghcr.io/ssimpson89/main-ee:latest-2.16` - Always points to the latest 2.16 release
- `ghcr.io/ssimpson89/main-ee:{version}-2.16` - Specific version (e.g., `2026.02.1-2.16`)
- `ghcr.io/ssimpson89/main-ee:dev-2.16` - Development builds

## Files Created

### Execution Environment Configurations
1. **execution-environment-2.16.yml** - Builds containers with Ansible 2.16
   - `ansible-core>=2.16.0,<2.17`
   
2. **execution-environment-2.20.yml** - Builds containers with Ansible 2.20
   - `ansible-core>=2.20.0,<2.21`

## Building Locally

### Using Make
```bash
# Build both versions
make build-all

# Build only Ansible 2.20 (latest)
make build-2.20

# Build only Ansible 2.16 (legacy)
make build-2.16

# Custom builds
make build ANSIBLE_VERSION=2.20 TAG=custom-tag:latest
make build ANSIBLE_VERSION=2.16 TAG=custom-tag:2.16
```

### Using build.sh
```bash
# Build Ansible 2.20 with podman
./build.sh podman ghcr.io/ssimpson89/main-ee:latest 2.20

# Build Ansible 2.16 with docker
./build.sh docker ghcr.io/ssimpson89/main-ee:latest-2.16 2.16
```

## CI/CD Workflows

### Release Workflow (`.github/workflows/release.yml`)
When a release is created, both versions are built and pushed automatically:
- Ansible 2.20 → `{version}` and `latest`
- Ansible 2.16 → `{version}-2.16` and `latest-2.16`

### Build-Test Workflow (`.github/workflows/build-test.yml`)
Manual workflow dispatch builds both dev versions:
- Ansible 2.20 → `dev`
- Ansible 2.16 → `dev-2.16`

## Usage Examples

### Using Ansible 2.20 (Latest)
```yaml
# In your automation platform or docker-compose
image: ghcr.io/ssimpson89/main-ee:latest
```

### Using Ansible 2.16 (Legacy)
```yaml
# For older systems requiring Ansible 2.16
image: ghcr.io/ssimpson89/main-ee:latest-2.16
```

### Pinning to Specific Versions
```yaml
# Pin to specific release with Ansible 2.20
image: ghcr.io/ssimpson89/main-ee:2026.02.1

# Pin to specific release with Ansible 2.16
image: ghcr.io/ssimpson89/main-ee:2026.02.1-2.16
```

## Migration Path

1. **New deployments** → Use `latest` or `{version}` (Ansible 2.20)
2. **Legacy systems** → Use `latest-2.16` or `{version}-2.16` (Ansible 2.16)
3. **Testing migration** → Try `dev` tag first, then switch to versioned releases
4. **Gradual rollout** → Migrate systems incrementally from 2.16 to 2.20

## Notes
- Both versions include the same collections and system dependencies
- The only difference is the `ansible-core` version
- Development (`dev`) tags are built manually via workflow dispatch
- Release tags are automatically created when a GitHub release is published
