# Static Linux ELF build

This repository includes a GitHub Actions workflow that builds a static
`autossh` ELF executable for Linux x86_64:

- workflow: `.github/workflows/static-linux-elf.yml`
- output: `autossh-linux-x86_64-static`
- artifact: `autossh-linux-x86_64-static` plus `autossh-linux-x86_64-static.sha256`

The build runs inside Alpine Linux and links with musl using `LDFLAGS=-static`.
That avoids a runtime dependency on the target distribution's glibc version, so
the same ELF is intended to run on common x86_64 distributions from CentOS 7 and
Ubuntu 20.04 through current releases.

The workflow also smoke-tests the resulting executable in these containers:

- `quay.io/centos/centos:7`
- `ubuntu:20.04`
- `ubuntu:22.04`
- `ubuntu:24.04`
- `ubuntu:latest`
- `debian:stable-slim`
- `almalinux:8`
- `almalinux:9`
- `rockylinux:9`
- `fedora:latest`

`autossh` still starts the system `ssh` client at runtime. The static binary does
not embed OpenSSH; target machines still need a compatible `ssh` executable,
normally `/usr/bin/ssh`.

## Run manually

On a Linux host with a C compiler and binutils:

```sh
sh ./scripts/build-static-linux.sh
```

For the same musl build environment used by GitHub Actions:

```sh
docker run --rm \
  -v "$PWD:/src" \
  -w /src \
  -e TARGET_NAME=autossh-linux-x86_64-static \
  alpine:3.20 \
  sh -euxc 'apk add --no-cache build-base binutils file openssh-client tar && sh ./scripts/build-static-linux.sh'
```

The generated files are written to `dist/`.
