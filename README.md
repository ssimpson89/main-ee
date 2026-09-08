# main-ee

Ansible Execution Environment images for Ascender, built with
[ansible-builder](https://github.com/ansible/ansible-builder).

Two variants are published, both for `linux/amd64` and `linux/arm64` as
multi-arch manifest lists, so a plain `podman pull` gets the right
architecture.

| Variant | ansible-core | Base | Interpreter | Use it for |
| --- | --- | --- | --- | --- |
| default | `>=2.20,<2.21` | Rocky Linux 10 | system `python3` | Everything current |
| legacy | `>=2.16.14,<2.17` | Rocky Linux 9 | `python3.11` | Managing EL8 and older targets |

The legacy variant exists because ansible-core 2.17 dropped Python 3.6
support, and EL8's `dnf`/`yum` modules run under the target's system Python
3.6. Anything 2.17 or newer cannot manage those hosts. It stays on Rocky 9
because ansible-core 2.16 does not support the controller Python that ships as
the default on Rocky 10.

The two variants share their pip and system package lists but **not** their
collections, and they differ in a few build steps besides the interpreter:
the legacy variant relaxes the crypto policy to allow SHA1 (so it can reach
EL7/EL8 endpoints), pulls `python3.11-rpm` from EPEL, and uses `alternatives`
to provide the unversioned `python` commands.

## Tags

| Tag | Contents |
| --- | --- |
| `ghcr.io/ssimpson89/main-ee:latest` | Newest release, ansible-core 2.20 |
| `ghcr.io/ssimpson89/main-ee:<release>` | Pinned release, ansible-core 2.20 |
| `ghcr.io/ssimpson89/main-ee:dev` | Nightly build, ansible-core 2.20 |
| `ghcr.io/ssimpson89/main-ee:latest-2.16` | Newest release, ansible-core 2.16 |
| `ghcr.io/ssimpson89/main-ee:<release>-2.16` | Pinned release, ansible-core 2.16 |
| `ghcr.io/ssimpson89/main-ee:dev-2.16` | Nightly build, ansible-core 2.16 |

Pin to a release tag in anything that matters. `latest` moves.

## Layout

```
requirements.yml                 collections, default variant, pinned
requirements-2.16.yml            collections, legacy variant, frozen
requirements.txt                 pip packages, both variants
bindep.txt                       system packages, both variants
execution-environment-2.20.yml   default variant
execution-environment-2.16.yml   legacy variant
includes/                        files copied into the images
.github/workflows/build.yml      reusable matrix build, called by the other three
```

### Adding a dependency

A pip package or an rpm goes in `requirements.txt` or `bindep.txt` once and
both variants pick it up. Each of those files documents what deliberately does
*not* belong in it, and why.

Collections are separate per variant on purpose. `requirements.yml` tracks
upstream for the default image. `requirements-2.16.yml` is **frozen**: it
holds the newest release of each collection that still supports core 2.16, and
it does not inherit additions to the default list. The legacy image exists to
keep managing EL8, not to gain new capability.

Two collections already differ, both forced by upstream `requires_ansible`:
`community.general` is held at 11.x on the legacy variant, and
`community.proxmox` is absent from it entirely, because every version ever
published requires core 2.17 or newer. Before adding a collection to
`requirements-2.16.yml`, check that its `requires_ansible` admits 2.16.

## Build locally

```bash
make install                        # ansible-builder, pinned to the CI version
make build-all                      # both variants
make build ANSIBLE_VERSION=2.16     # one variant
make create                         # generate context/ without building
make help                           # targets and variables
```

`RUNTIME` (default `podman`, `docker` also works), `TAG` and `ANSIBLE_VERSION`
are all overridable. `make create` is the fastest way to see what a change
actually produces. `make clean` removes local images and `context/`.

Local builds are single-arch and native. Multi-arch assembly happens in CI.

## CI

`.github/workflows/build.yml` is reusable and does the work: a 2 variants by 2
arches matrix, each job pushing by digest, then one manifest-merge job per
variant that refuses to publish unless both arch digests are present.

- `pr.yml` builds both variants on pull requests with `push: false`, so a bad
  dependency fails on the PR rather than on release day.
- `release.yml` publishes `<release>` and `latest` when a release is created.
- `build-test.yml` publishes `dev` nightly and on manual dispatch.

arm64 runs on `ubuntu-24.04-arm` hosted runners, which are free on public
repositories and billed on private ones.
