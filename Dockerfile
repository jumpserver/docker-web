FROM nginx:stable-alpine

RUN set -e \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache bash iproute2 busybox-extras \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && sed -i 's@/bin/ash@/bin/bash@g' /etc/passwd \
    && mkdir -p /opt/download /etc/nginx/sites-enabled \
    && cd /opt/download \
    && wget https://download.jumpserver.org/public/JumpServer-Client-Installer.dmg \
    && wget https://download.jumpserver.org/public/JumpServer-Client-Installer.msi \
    && wget https://download.jumpserver.org/public/Microsoft_Remote_Desktop_10.6.7_installer.pkg \
    && rm -rf /var/cache/apk/*

COPY bashrc /root/.bashrc
COPY release/lina /opt/lina
COPY release/luna /opt/luna
COPY nginx.conf /etc/nginx/nginx.conf
COPY http_server.conf /etc/nginx/conf.d/default.conf
COPY init.sh /docker-entrypoint.d/40-init-config.sh
