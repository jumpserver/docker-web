# JumpServer Web

JumpServer 的 LB Nginx Build 项目，其中包含 Lina, Luna 和一些静态安装包文件

桌面客户端和 WebLite 由 Luna 独立发布，不包含在 `web-static` 和 CE 镜像中。
`Dockerfile-ee` 构建时通过 `client.sh` 下载客户端到 `/opt/download/public/`，并将
WebLite MSI 下载到 `/opt/download/applets/`。
现有 `/download/public/Client_<version>_...` 下载地址保持不变；CE 镜像中本地文件不存在时，
Nginx 会回源到公共静态文件服务。

`client-version.txt` 分别用 `CLIENT_VERSION`、`WEBLITE_VERSION` 固定两个产品的版本，
下载时分别使用 `client-v<version>`、`weblite-v<version>` Release tag，安装包文件名保持不变。
可分别使用 `CLIENT_RELEASE_URL`、`WEBLITE_RELEASE_URL` 覆盖下载源。

Luna 将正式发布的文件同步到 OSS 后，分别发送 `client-released`、`weblite-released` 通知。
版本检查每次分页查询最近最多 1,000 个 Release，分别选择两个产品的完整正式版本，
避免迟到通知降级版本或覆盖另一产品的更新；没有候选版本时保留原固定值。
定时检查使用同一规则，候选 Release 必须包含所需安装包且文件非空。
更新该文件不会触发 `web-static` 重建；Web / Core 镜像仍按服务端版本发布。

WebLite 清单同步只读取 `WEBLITE_VERSION`，自动向 Core 的 `dev` 创建或更新 PR，
同步 `manifest.yml`、`setup.yml`、`uninstall.yml`。Client 更新不会推进 WebLite 清单。
合并后需配套发布 Web / Core 镜像，确保离线环境的清单版本与内置 MSI 一致。

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
