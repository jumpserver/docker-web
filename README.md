# JumpServer Web

**English** | [中文](./README_ZH.md)

JumpServer Web gives administrators and users one address for the JumpServer management console, web terminal, and client downloads. The `jumpserver/web` image bundles the Lina and Luna frontends and uses Nginx to serve them and route API and session traffic to the JumpServer services. Deploy it alongside those services to give users a single HTTP or HTTPS entry point. [JumpServer](https://github.com/jumpserver/jumpserver)

## FAQ

### Which image should I choose?

| If you need… | Choose |
| --- | --- |
| The management console, web terminal, and Linux PAM Agent downloads | **CE**, built from [`Dockerfile`](./Dockerfile) |
| The same features plus locally hosted session playback, desktop client installers, WebLite, and applet dependencies | **EE**, built from [`Dockerfile-ee`](./Dockerfile-ee) |

### What can users access, including in offline deployments?

| Path | What users get |
| --- | --- |
| `/` or `/ui/` | The Lina management console |
| `/luna/` | The Luna web terminal and connection workspace |
| `/download/pam/` | PAM Agent binaries for Linux `amd64` and `arm64`, plus `SHA256SUMS`, in both editions |
| `/download/public/` | JumpServer Desktop Client installers for Windows x64 and macOS Apple silicon in EE |
| `/download/applets/` | The WebLite x64 MSI and offline applet packages such as Tinker and DBX in EE |
| `/player/` | The session recording player in EE |

Both editions serve bundled downloads from the Web container. For any file missing under `/download/`, the bundled Nginx configuration redirects the browser to the same path on `static.jumpserver.org`. In an offline deployment, verify that the image contains each file your users need. See [`includes/common.conf`](./includes/common.conf).

### What should I check after deployment?

Replace the example address with your deployed Web URL, including its scheme and port.

```bash
JMS_URL=https://jumpserver.example.com
curl -fsS "$JMS_URL/web/health/"
# Expected response: {"status": "ok"}
```

The health endpoint checks that the Web container can respond. To verify the full path, sign in at `/ui/` and open a web terminal from `/luna/`. If either action fails, check that the enabled backend services are running and their upstream names resolve from the Web container. The bundled routes cover Core, Koko, Chen, Kael, Razor, and JDMC. See [`includes/`](./includes/).

### How do I configure HTTPS, a reverse proxy, or backend routes?

These settings apply when the container starts with the bundled Nginx templates. See [`init.sh`](./init.sh).

| I want to… | Set |
| --- | --- |
| Serve HTTPS for my domain | Set `SERVER_NAME` and mount your certificate and key under `/etc/nginx/cert/`. The default filenames are `server.crt` and `server.key`. Set `SSL_CERTIFICATE` and `SSL_CERTIFICATE_KEY` for custom filenames. Map the host port to container port `443`. |
| Redirect HTTP to HTTPS | Set `HTTPS_PORT` to the externally published HTTPS port, such as `443` or `8443`. The container listens on `80` and `443`. |
| Forward the client address through a trusted upstream proxy | Set `USE_LB=0` when the upstream proxy manages `X-Forwarded-For`. The default `USE_LB=1` sets the forwarded address to the direct peer address. |
| Enable IPv6, adjust the request body limit, or disable compression | Use `USE_IPV6=1`, `CLIENT_MAX_BODY_SIZE`, or `GZIP=off`. |
| Disable a backend route or enable enterprise routes | Set the corresponding `CORE_ENABLED`, `KOKO_ENABLED`, `CHEN_ENABLED`, or `KAEL_ENABLED` to `0` to disable its route. `USE_XPACK=1` enables JDMC and also enables Razor unless `RAZOR_ENABLED=0`. |

When Helm mounts `/etc/nginx/sites-enabled/jms.conf`, the startup script uses that file as the site configuration. Manage TLS and component routes through the chart's configuration.

### How do I build an image from this checkout?

Run Docker Buildx Bake from the repository root. It builds Lina and Luna as dependencies and loads the selected Web image into Docker by default. The EE target also builds CE and pulls the `jumpserver/web-static` image pinned in `Dockerfile-ee`. See [`docker-bake.hcl`](./docker-bake.hcl).

```bash
VERSION=dev docker buildx bake       # jumpserver/web:dev-ce
VERSION=dev docker buildx bake ee    # jumpserver/web:dev-ee
```

Set `LINA_BRANCH` and `LUNA_BRANCH` to select frontend branches, `PAM_AGENT_VERSION` to override the pinned PAM Agent release, or `PUSH_ENABLED=true` to push the selected Web image to the registry.

If your builder can already resolve `jumpserver/lina:${VERSION}` and `jumpserver/luna:${VERSION}`, you can build CE directly.

```bash
VERSION=dev
docker buildx build --build-arg VERSION="${VERSION}" \
  -t "jumpserver/web:${VERSION}-ce" --load .
```

### Which image do I rebuild to update an installer or the session player?

| Asset | Version file and downloader | Rebuild |
| --- | --- | --- |
| PAM Agent | [`pam-agent-version.txt`](./pam-agent-version.txt) · [`pam-agent.sh`](./pam-agent.sh). The build downloads both Linux binaries and verifies them against `SHA256SUMS`. | CE, then EE if you ship it |
| Desktop Client or WebLite | [`client-version.txt`](./client-version.txt) · [`client.sh`](./client.sh). `CLIENT_VERSION` and `WEBLITE_VERSION` pin separate Luna releases. The Desktop Client keeps the `Client_<ver>_*` compatibility symlinks. | EE only |
| Session player, Tinker, DBX, OpenSSH, or `mongosh` | [`versions.txt`](./versions.txt) · [`static.sh`](./static.sh). Update the corresponding JumpServer references listed in `versions.txt` when changing versions. | `web-static`, then EE with the new base image tag |

Build a local copy of the offline asset image with `Dockerfile-static`.

```bash
docker buildx build -f Dockerfile-static -t jumpserver/web-static:dev --load .
```
