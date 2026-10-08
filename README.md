# JumpServer Web

JumpServer 的 LB Nginx Build 项目，其中包含 Lina, Luna 和一些静态安装包文件

桌面客户端和 WebLite 由 Luna 独立发布，不包含在 `web-static` 和 CE 镜像中。
`Dockerfile-ee` 构建时通过 `client.sh` 下载客户端到 `/opt/download/public/`，并将
WebLite MSI 下载到 `/opt/download/applets/`。
现有 `/download/public/Client_<version>_...` 下载地址保持不变；CE 镜像中本地文件不存在时，
Nginx 会回源到公共静态文件服务。客户端和 WebLite 共用 `client-version.txt` 中的 Luna 版本，
更新该文件不会触发 `web-static` 重建。

## Docker 构建

```bash
VERSION=dev
docker buildx build --build-arg VERSION=${VERSION} -t jumpserver/web:${VERSION} . --load
```

## PAM Agent 安装包

SDK / Agent 在 `jumpserver/pam-clients` 仓库独立发布。tag CI 编译 Linux amd64 / arm64
Agent，上传二进制、SDK 源码压缩包和 `SHA256SUMS` 到草稿 Release，审核后发布。

Web 通过 `pam-agent.sh` 从该仓库下载并校验 Agent，CE / EE 均包含。
`pam-agent-version.txt` 固定独立客户端版本，也可使用构建参数 `PAM_AGENT_VERSION` 覆盖。
它与 Web / JumpServer 的 `VERSION` 无关，开发镜像也使用固定版本。

当前固定为 `1.0.1`，对应 pam-clients 的 `v1.0.1` Release。
后续 Web 构建复用已发布版本，无需等待 JumpServer Release。
文件缺失或校验失败会使构建失败。

用户下载地址：

- `/download/pam/jms-pam-agent-linux-amd64`
- `/download/pam/jms-pam-agent-linux-arm64`
- `/download/pam/SHA256SUMS`

用户文档直接链接当前 JumpServer 的上述地址，无需获取源码或编译。
