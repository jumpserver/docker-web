# JumpServer Web

JumpServer 的 LB Nginx Build 项目，其中包含 Lina, Luna 和一些静态安装包文件

## Docker 构建
```bash
VERSION=dev
docker run --rm -i -v $(pwd)/release:/tmp/data jumpserver/lina:${VERSION} cp -R /opt/lina /tmp/data
docker run --rm -i -v $(pwd)/release:/tmp/data jumpserver/luna:${VERSION} cp -R /opt/lina /tmp/data
docker run --rm -i -v $(pwd)/release:/tmp/data jumpserver/applets:${VERSION} cp -R /opt/applets /tmp/data
```
```bash
ls -al release
```
```bash
docker buildx build --build-arg VERSION=${VERSION} -t jumpserver/web:${VERSION} . --load
```
