# main-ee

Ansible Execution Environment images for Ascender, built with
[ansible-builder](https://github.com/ansible/ansible-builder).

Two variants are published from one shared set of requirements. They carry the
same collections, python packages and system packages; only the interpreter
and the `ansible-core` pin differ.

| Variant | ansible-core | Base | Interpreter | Use it for |
| --- | --- | --- | --- | --- |
| default | `>=2.20,<2.21` | Rocky Linux 10 | system `python3` | Everything current |
| legacy | `>=2.16.14,<2.17` | Rocky Linux 9 | `python3.11` | Managing EL8 and older targets |

The legacy variant exists because ansible-core 2.17 dropped Python 3.6
support, and EL8's `dnf`/`yum` modules run under the target's system Python
3.6. Anything 2.17 or newer cannot manage those hosts. It stays on Rocky 9
because ansible-core 2.16 does not support the controller Python that ships
as the default on Rocky 10.

Both variants are published for `linux/amd64` and `linux/arm64` as multi-arch
manifest lists, so a plain `podman pull` gets the right architecture.

## Tags

| Tag | Contents |
| --- | --- |
| `ghcr.io/ssimpson89/main-ee:latest` | Newest release, ansible-core 2.20 |
| `ghcr.io/ssimpson89/main-ee:<release>` | Pinned release, ansible-core 2.20 |
| `ghcr.io/ssimpson89/main-ee:dev` | Manual dev build, ansible-core 2.20 |
| `ghcr.io/ssimpson89/main-ee:latest-2.16` | Newest release, ansible-core 2.16 |
| `ghcr.io/ssimpson89/main-ee:<release>-2.16` | Pinned release, ansible-core 2.16 |
| `ghcr.io/ssimpson89/main-ee:dev-2.16` | Manual dev build, ansible-core 2.16 |

Pin to a release tag in anything that matters. `latest` moves.

`buildcache-*` tags are buildx layer cache, not runnable images.

## Layout

```
requirements.yml                 collections, shared by both variants
requirements.txt                 python packages, shared by both variants
bindep.txt                       system packages, shared by both variants
execution-environment.yml        default variant (2.20 / Rocky 10)
execution-environment-2.16.yml   legacy variant (2.16 / Rocky 9)
includes/                        files copied into the images
.github/workflows/build.yml      reusable matrix build, called by the other two
```

To add a collection, a pip package, or an rpm, edit the matching shared file
once. Both variants pick it up. Only touch an `execution-environment*.yml`
when the change is genuinely specific to one ansible-core version.

Two things `bindep.txt` deliberately does not do, both documented in the file
itself: it does not name a python-versioned package, because bindep cannot
template the interpreter and the variants use different ones (those are
installed via `$PYPKG` in the EE files), and it does not pin an architecture,
because a hardcoded arch breaks the arm64 build.

## Build locally

```bash
make install        # ansible-builder, pinned to the version CI uses
make build-all      # both variants
make build-2.20     # default variant only
make build-2.16     # legacy variant only
make help           # targets and variables
```

Override `RUNTIME` (`podman` is the default, `docker` also works), `TAG`, or
`ANSIBLE_VERSION`:

```bash
make build ANSIBLE_VERSION=2.16 TAG=my-ee:test RUNTIME=docker
```

`make create` generates the `context/` directory and its `Containerfile`
without building, which is the fastest way to check what a change actually
produces. `make clean` removes local images and that directory.

Local builds are single-arch and native. Multi-arch assembly happens in CI,
where each arch builds on its own native runner.

## CI

`.github/workflows/build.yml` is reusable and does the real work: a
2 variants by 2 arches matrix, each job pushing by digest, then one
manifest-merge job per variant.

- `release.yml` runs it when a GitHub release is created, tagging
  `<release>` and `latest`.
- `build-test.yml` runs it on manual dispatch, tagging `dev`.

Builds use `ubuntu-24.04` and `ubuntu-24.04-arm` runners rather than QEMU,
because several dependencies (`pykerberos`, `requests-credssp`,
`ovirt-engine-sdk-python`) have no prebuilt aarch64 wheels and compile from
source. Note that arm64 hosted runners are free on public repositories but
billed on private ones.
