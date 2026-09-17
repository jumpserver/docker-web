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
