# JumpServer Web

**English** | [中文](./README_ZH.md)

The web container image (`jumpserver/web`) for [JumpServer](https://github.com/jumpserver/jumpserver). It runs Nginx as the unified HTTP/HTTPS entry point, bundles the [Lina](https://github.com/jumpserver/lina) and [Luna](https://github.com/jumpserver/luna) web frontends, and serves static download assets.

## What's Inside

- **Nginx reverse proxy**: Terminates HTTP/HTTPS traffic and routes requests to JumpServer backend components (`core`, `koko`, `chen`, `kael`, `razor`, `jdmc`).
- **Lina** (`/ui/`): Management console frontend, copied from `jumpserver/lina`.
- **Luna** (`/luna/`): Web terminal and session workspace frontend, copied from `jumpserver/luna`.
- **Static assets** (`/download/`, `/player/`):
  - **CE (`Dockerfile`)**: Includes Lina, Luna, and the PAM Agent binaries under `/download/pam/`. Requests for files under `/download/` that are not bundled locally fall back to `https://static.jumpserver.org/download/`.
  - **EE (`Dockerfile-ee`)**: Extends the CE image with offline packages from `jumpserver/web-static` (session player, Tinker, DBX, OpenSSH, `mongosh`, etc.) plus JumpServer Desktop Client and WebLite installers.

## Build

Build the CE image directly (requires `jumpserver/lina:${VERSION}` and `jumpserver/luna:${VERSION}`):

```bash
VERSION=dev
docker buildx build --build-arg VERSION=${VERSION} -t jumpserver/web:${VERSION}-ce . --load
```

Or use `docker-bake.hcl` to build Lina, Luna, and Web together:

```bash
# Build CE (default target)
VERSION=dev docker buildx bake

# Build EE
VERSION=dev docker buildx bake ee
```

Common build variables in `docker-bake.hcl`: `VERSION`, `LINA_BRANCH`, `LUNA_BRANCH`, `PAM_AGENT_VERSION`, `PUSH_ENABLED`.

To build the offline static asset base image (`jumpserver/web-static`):

```bash
docker buildx build -f Dockerfile-static -t jumpserver/web-static:dev . --load
```

## Static Assets & Version Files

Static packages are pinned in three separate files:

| File | Script | Scope | Description |
| --- | --- | --- | --- |
| `pam-agent-version.txt` | `pam-agent.sh` | CE & EE | Pins the [`jumpserver/pam-clients`](https://github.com/jumpserver/pam-clients) release. Downloads and SHA256-verifies `jms-pam-agent-linux-amd64`, `jms-pam-agent-linux-arm64`, and `SHA256SUMS` to `/opt/download/pam/` (served at `/download/pam/`). Can be overridden with `--build-arg PAM_AGENT_VERSION=<ver>`. |
| `client-version.txt` | `client.sh` | EE only | Pins `CLIENT_VERSION` and `WEBLITE_VERSION` independently (`client-v<ver>` and `weblite-v<ver>` releases in [`jumpserver/luna`](https://github.com/jumpserver/luna)). Downloads client installers to `/opt/download/public/` (with `Client_<ver>_*` symlinks) and WebLite MSI to `/opt/download/applets/`. Updating this file does not require rebuilding `web-static`. |
| `versions.txt` | `static.sh` | `web-static` / EE | Pins the session player and offline applet/tool packages (`Dockerfile-static`). Keep version changes in sync with the references noted in `versions.txt`. |

## Runtime Configuration

`init.sh` configures Nginx at container startup using environment variables (for standard deployments; Helm deployments mount `/etc/nginx/sites-enabled/jms.conf`):

- **HTTP / HTTPS**: `SERVER_NAME`, `HTTPS_PORT`, `SSL_CERTIFICATE`, `SSL_CERTIFICATE_KEY`, `USE_IPV6`, `CLIENT_MAX_BODY_SIZE`, `GZIP`
- **Proxy behavior**: `USE_LB` (defaults to `1`, discarding client-supplied `X-Forwarded-For`; set to `0` when behind a trusted upstream proxy)
- **Components**: `CORE_ENABLED`, `KOKO_ENABLED`, `CHEN_ENABLED`, `KAEL_ENABLED`, `USE_XPACK`, `RAZOR_ENABLED`
