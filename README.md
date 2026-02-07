# AWX EE

The default Execution Environment for AWX.

## Build the image locally

### Option 1: Direct Command (Simplest)

First, install ansible-builder:

```bash
pip install 'git+https://github.com/ansible/ansible-builder.git@devel#egg=ansible-builder'
```

Then build:

```bash
# With podman (default)
ansible-builder build -v3 -t ghcr.io/ssimpson89/ascender-ee

# With docker
ansible-builder build -v3 -t ghcr.io/ssimpson89/ascender-ee --container-runtime=docker
```

### Option 2: Using Build Script

```bash
# With podman (default)
./build.sh

# With docker
./build.sh docker

# Custom tag
./build.sh podman my-custom-tag:latest
```

### Option 3: Using Makefile

```bash
# Install dependencies
make install

# Build with podman (default)
make build

# Build with docker
make build-docker

# Custom tag
make build TAG=my-custom-tag:latest

# Show all available targets
make help
```
