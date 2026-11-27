# JumpServer Web

[English](./README.md) | **中文**

管理员和用户通过同一个地址就可以打开 JumpServer 管理后台、使用 Web 终端和下载客户端。`jumpserver/web` 镜像内置 Lina 和 Luna，使用 Nginx 提供页面，并把 API 和会话流量转发给 JumpServer 后端。与后端服务一起部署，即可提供统一的 HTTP/HTTPS 入口。[JumpServer](https://github.com/jumpserver/jumpserver)

## 常见问题

### 我该选 CE 还是 EE？

| 需求 | 镜像 |
| --- | --- |
| 使用管理后台、Web 终端，并提供 Linux PAM Agent 下载 | **CE**，由 [`Dockerfile`](./Dockerfile) 构建 |
| 在上述功能之外，本地提供录像回放、桌面客户端、WebLite 和应用发布依赖 | **EE**，由 [`Dockerfile-ee`](./Dockerfile-ee) 构建 |

### 用户能访问什么？离线时还能下载哪些文件？

| 路径 | 可访问的内容 |
| --- | --- |
| `/` 或 `/ui/` | Lina 管理后台 |
| `/luna/` | Luna Web 终端与连接工作台 |
| `/download/pam/` | CE 和 EE 都提供 Linux `amd64`、`arm64` 的 PAM Agent 二进制文件和 `SHA256SUMS` |
| `/download/public/` | EE 提供 Windows x64 和 Apple 芯片 Mac 的 JumpServer 桌面客户端安装包 |
| `/download/applets/` | EE 提供 WebLite x64 MSI 以及 Tinker、DBX 等离线应用包 |
| `/player/` | EE 提供录像播放器 |

两个版本都由 Web 容器直接提供镜像内已打包的文件。请求 `/download/` 下缺失的文件时，内置 Nginx 配置会将浏览器重定向到 `static.jumpserver.org` 上的同一路径。离线部署时，请确认镜像已包含用户需要下载的每个文件。见 [`includes/common.conf`](./includes/common.conf)。

### 部署后怎么确认能用？

将示例地址替换为实际部署的 Web 地址，带上协议和端口。

```bash
JMS_URL=https://jumpserver.example.com
curl -fsS "$JMS_URL/web/health/"
# 预期响应: {"status": "ok"}
```

健康检查用于确认 Web 容器能够响应。要验证完整访问链路，再到 `/ui/` 登录，从 `/luna/` 打开一个 Web 终端。如果登录或连接失败，检查已启用的后端是否运行，以及 Web 容器能否解析相应的上游地址。Chen 数据库工作台通过 `/koko/chen/` 访问，Kael 通过 `/kael/` 访问，两者都转发到 Koko。见 [`includes/`](./includes/)。

### 怎么配置 HTTPS、前置代理和后端路由？

以下设置适用于容器启动时使用内置 Nginx 模板的部署方式。见 [`init.sh`](./init.sh)。

| 需求 | 配置 |
| --- | --- |
| 用自己的域名提供 HTTPS | 设置 `SERVER_NAME`，把证书和私钥挂载到 `/etc/nginx/cert/`。默认文件名为 `server.crt` 和 `server.key`，可用 `SSL_CERTIFICATE` 和 `SSL_CERTIFICATE_KEY` 指定其他文件名。将宿主机端口映射到容器的 `443`。 |
| 将 HTTP 请求跳转到 HTTPS | 将 `HTTPS_PORT` 设为对外发布的 HTTPS 端口，例如 `443` 或 `8443`。容器内监听 `80` 和 `443`。 |
| 通过可信前置代理传递客户端地址 | 前置代理负责管理 `X-Forwarded-For` 时，设置 `USE_LB=0`。默认的 `USE_LB=1` 会将转发头设置为直接连接方的地址。 |
| 启用 IPv6、调整请求体大小上限或关闭压缩 | 分别使用 `USE_IPV6=1`、`CLIENT_MAX_BODY_SIZE` 和 `GZIP=off`。 |
| 关闭后端路由或启用企业组件路由 | 设置 `CORE_ENABLED=0` 可关闭 Core 路由。`KOKO_ENABLED=0` 关闭 Koko 和 Kael 路由，`KAEL_ENABLED=0` 仅关闭 Kael 路由。`USE_XPACK=1` 会启用 JDMC，同时启用 Razor，后者可通过 `RAZOR_ENABLED=0` 关闭。 |

Helm 挂载 `/etc/nginx/sites-enabled/jms.conf` 时，启动脚本会将该文件用作站点配置。请通过 Chart 配置管理 TLS 和组件路由。

### 怎么从源码构建镜像？

在仓库根目录运行 Docker Buildx Bake。它会构建 Lina 和 Luna 依赖，并默认将选中的 Web 镜像加载到 Docker。构建 EE 时还会构建 CE，并拉取 `Dockerfile-ee` 中固定的 `jumpserver/web-static` 镜像。见 [`docker-bake.hcl`](./docker-bake.hcl)。

```bash
VERSION=dev docker buildx bake       # jumpserver/web:dev-ce
VERSION=dev docker buildx bake ee    # jumpserver/web:dev-ee
```

可通过 `LINA_BRANCH` 和 `LUNA_BRANCH` 指定前端分支，用 `PAM_AGENT_VERSION` 覆盖固定的 PAM Agent 版本，或设置 `PUSH_ENABLED=true` 将选中的 Web 镜像推送到镜像仓库。

如果构建器已能找到 `jumpserver/lina:${VERSION}` 和 `jumpserver/luna:${VERSION}`，可以直接构建 CE。

```bash
VERSION=dev
docker buildx build --build-arg VERSION="${VERSION}" \
  -t "jumpserver/web:${VERSION}-ce" --load .
```

### 更新安装包或录像播放器时，要重建哪个镜像？

| 资源 | 版本文件与下载脚本 | 需要重建 |
| --- | --- | --- |
| PAM Agent | [`pam-agent-version.txt`](./pam-agent-version.txt) · [`pam-agent.sh`](./pam-agent.sh)。构建时下载两个架构的 Linux 二进制文件，并按 `SHA256SUMS` 校验。 | CE，若发布 EE 则随后重建 EE |
| 桌面客户端或 WebLite | [`client-version.txt`](./client-version.txt) · [`client.sh`](./client.sh)。`CLIENT_VERSION` 和 `WEBLITE_VERSION` 分别固定 Luna 中的两个发布版本。桌面客户端保留 `Client_<ver>_*` 兼容软链接。 | 仅 EE |
| 录像播放器、Tinker、DBX、OpenSSH 或 `mongosh` | [`versions.txt`](./versions.txt) · [`static.sh`](./static.sh)。更新版本时同步修改 `versions.txt` 注释中列出的 JumpServer 关联位置。 | 先重建 `web-static`，再引用新的基础镜像标签重建 EE |

使用 `Dockerfile-static` 在本地构建离线资源镜像。

```bash
docker buildx build -f Dockerfile-static -t jumpserver/web-static:dev --load .
```

## 许可证

Copyright (c) 2014-2026 FIT2CLOUD, All rights reserved.

本项目基于 GNU General Public License version 3（GPLv3）许可，与 [JumpServer 主仓库](https://github.com/jumpserver/jumpserver)一致。完整许可文本请参阅 [LICENSE](LICENSE)。
