# JumpServer Web

[English](./README.md) | **中文**

[JumpServer](https://github.com/jumpserver/jumpserver) 的 Web 容器镜像（`jumpserver/web`）。基于 Nginx 提供统一的 HTTP/HTTPS 访问入口，内置 [Lina](https://github.com/jumpserver/lina) 和 [Luna](https://github.com/jumpserver/luna) 前端以及静态下载资源。

## 镜像内容

- **Nginx 反向代理**：处理 HTTP/HTTPS 流量并转发至各后端组件（`core`、`koko`、`chen`、`kael`、`razor`、`jdmc`）。
- **Lina**（`/ui/`）：管理后台前端，来自 `jumpserver/lina` 镜像。
- **Luna**（`/luna/`）：Web 终端与连接工作台前端，来自 `jumpserver/luna` 镜像。
- **静态资源**（`/download/`、`/player/`）：
  - **CE 镜像（`Dockerfile`）**：包含 Lina、Luna 以及 `/download/pam/` 下的 PAM Agent 安装包。请求 `/download/` 下本地不存在的文件时，Nginx 会重定向到 `https://static.jumpserver.org/download/`。
  - **EE 镜像（`Dockerfile-ee`）**：基于 CE 镜像构建，额外打包 `jumpserver/web-static` 中的离线静态资源（录像播放器、Tinker、DBX、OpenSSH、`mongosh` 等）以及 JumpServer 桌面客户端和 WebLite 安装包。

## 构建镜像

单独构建 CE 镜像（需提前存在 `jumpserver/lina:${VERSION}` 和 `jumpserver/luna:${VERSION}`）：

```bash
VERSION=dev
docker buildx build --build-arg VERSION=${VERSION} -t jumpserver/web:${VERSION}-ce . --load
```

或通过 `docker-bake.hcl` 联动构建 Lina、Luna 与 Web：

```bash
# 构建 CE（默认 target）
VERSION=dev docker buildx bake

# 构建 EE
VERSION=dev docker buildx bake ee
```

`docker-bake.hcl` 支持的常用变量：`VERSION`、`LINA_BRANCH`、`LUNA_BRANCH`、`PAM_AGENT_VERSION`、`PUSH_ENABLED`。

构建离线静态资源基础镜像（`jumpserver/web-static`）：

```bash
docker buildx build -f Dockerfile-static -t jumpserver/web-static:dev . --load
```

## 静态资源与版本管理

静态安装包的版本通过以下三个文件分别维护：

| 文件 | 脚本 | 适用镜像 | 说明 |
| --- | --- | --- | --- |
| `pam-agent-version.txt` | `pam-agent.sh` | CE / EE | 固定 [`jumpserver/pam-clients`](https://github.com/jumpserver/pam-clients) 发布版本，下载并校验 `jms-pam-agent-linux-amd64`、`jms-pam-agent-linux-arm64` 和 `SHA256SUMS` 至 `/opt/download/pam/`（下载地址 `/download/pam/`）。可通过 `--build-arg PAM_AGENT_VERSION=<ver>` 覆盖。 |
| `client-version.txt` | `client.sh` | 仅 EE | 分别通过 `CLIENT_VERSION` 和 `WEBLITE_VERSION` 固定 [`jumpserver/luna`](https://github.com/jumpserver/luna) 发布的桌面客户端（`client-v<ver>`）和 WebLite（`weblite-v<ver>`）版本，下载至 `/opt/download/public/`（保留 `Client_<ver>_*` 软链）和 `/opt/download/applets/`。更新此文件无需重建 `web-static`。 |
| `versions.txt` | `static.sh` | `web-static` / EE | 固定录像播放器及离线依赖包版本（`Dockerfile-static`）。调整版本时需同步更新文件中注释标注的关联位置。 |

## 运行时配置

容器启动时由 `init.sh` 根据环境变量生成 Nginx 配置（Helm 部署会挂载 `/etc/nginx/sites-enabled/jms.conf`）：

- **HTTP / HTTPS**：`SERVER_NAME`、`HTTPS_PORT`、`SSL_CERTIFICATE`、`SSL_CERTIFICATE_KEY`、`USE_IPV6`、`CLIENT_MAX_BODY_SIZE`、`GZIP`
- **代理行为**：`USE_LB`（默认为 `1`，不信任客户端传入的 `X-Forwarded-For`；前置存在可信反向代理时设为 `0`）
- **组件开关**：`CORE_ENABLED`、`KOKO_ENABLED`、`CHEN_ENABLED`、`KAEL_ENABLED`、`USE_XPACK`、`RAZOR_ENABLED`
