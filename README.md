# USK 2.80 toolchain snapshot

Prebuilt tools for [supersnug/usk](https://github.com/supersnug/usk), frozen to
**2024-09-04 04:12:04 UTC**, when rehius/usk 2.80 was published. Build the image
once so firmware builds no longer download and install 540 MB of dependencies.
This repository contains build infrastructure, not firmware or the Pico SDK.

## Frozen inputs

- Ubuntu `jammy-20240808`, amd64 manifest
  `sha256:075680e983398fda61b1ac59ad733ad81d18df4bc46411666bb8a03fb9ea0195`.
- Ubuntu packages and transitive dependencies from the `20240904T041204Z`
  snapshot: ARM GCC 10.3.1, Newlib, host GCC 11.4, Make, Python 3.10.12,
  Git, curl and their normal recommended packages.
- CMake 3.30.2, official Linux x86-64 archive, verified against SHA-256
  `cdd7fb352605cee3ae53b0e18b5929b642900e33d6b0173e19f6d4f2067ebf16`.
- Checkout action pinned to v3.6.0's commit.

These are the same package selections and CMake archive used for the local
reconstruction that reproduced both original USK 2.80 binaries byte-for-byte.
That verification predates this Docker recipe; the published image must still
be checked by building the firmware with it.

## Publish once

1. Push this recipe and workflow to the repository's default branch.
2. In Actions, manually run **Publish USK 2.80 toolchain**. It uses the job's
   `GITHUB_TOKEN` with `packages: write`; no personal token or registry secret
   needs to be configured. The first build still performs the slow install.
3. The image is published as `ghcr.io/supersnug/usk-toolchain:2.80`. Copy the
   **digest-pinned reference** printed in the run summary.
4. In the GHCR package settings, make the package **public** so the separate
   `usk` repository can pull it without cross-repository package credentials.
   New GHCR packages are private by default, even for public repositories.
5. Set `jobs.build.container.image` in `usk` to that digest-pinned reference.
   Remove its dependency/CMake installation steps, bootstrap certificate mount,
   and `DEBIAN_FRONTEND` setting; CMake is already on the image's PATH.
   Leave the SDK, picotool, firmware source pins and build commands unchanged.

The workflow runs only manually. Publishing again may move the `2.80` tag,
but cannot change an existing digest. Never replace an existing firmware
workflow's digest without validating the replacement image.

## Build locally

Requires Docker with BuildKit/buildx and a host CA bundle. On Ubuntu:

```bash
docker buildx build --platform linux/amd64 \
  --secret id=bootstrap_ca,src=/etc/ssl/certs/ca-certificates.crt \
  --tag usk-toolchain:2.80 --load .
docker run --rm usk-toolchain:2.80 cmake --version
```

The CA bundle is a build secret for initial HTTPS access, not a persistent
image layer. APT signature checks remain enabled. CMake and all libraries are
installed inside the image, with no build-time dependencies on host libraries.

## Verify firmware outputs

Using this image with the source/SDK/picotool pins in `usk` should produce:

| Output | SHA-256 of upstream 2.80 release |
| --- | --- |
| `firmware.uf2` | `e2fb2d4bce9d69db294a71b6304c33c443bd13a75d0cdc1424e55ff58feed831` |
| `update.bin` | `d95f8e2cd89c4618d5ddeb33a28886281cf0dd103ad7fa9215697940dd3ebb02` |

The GitHub runner, Docker/BuildKit and Actions JavaScript runtime remain managed
infrastructure; the published image is the immutable build-tool boundary.
An image pull still transfers data, but avoids reinstalling packages each run.
Historical tools intentionally receive no automatic security updates; build
only trusted snapshot sources. The repository license covers these recipes;
bundled packages retain their own licenses.
