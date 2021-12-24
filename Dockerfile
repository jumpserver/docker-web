FROM nginx:stable-alpine

ARG Jmservisor_VERSION=v1.1.0
ARG Client_VERSION=v1.1.1
ARG MRD_VERSION=10.6.7

RUN set -e \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache bash iproute2 busybox-extras \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && sed -i 's@/bin/ash@/bin/bash@g' /etc/passwd \
    && mkdir -p /opt/download /etc/nginx/sites-enabled \
    && cd /opt/download \
    && wget -qO /opt/download/Jmservisor.msi https://download.jumpserver.org/public/Jmservisor-${Jmservisor_VERSION}.msi \
    && wget -qO /opt/download/JumpServer-Client-Installer.msi https://download.jumpserver.org/public/JumpServer-Client-Installer-${Client_VERSION}.msi \
    && wget -qO /opt/download/JumpServer-Client-Installer.dmg https://download.jumpserver.org/public/JumpServer-Client-Installer-${Client_VERSION}.dmg \
    && wget https://download.jumpserver.org/public/Microsoft_Remote_Desktop_${MRD_VERSION}_installer.pkg \
    && rm -rf /var/cache/apk/*

COPY bashrc /root/.bashrc
COPY release/lina /opt/lina
COPY release/luna /opt/luna
COPY nginx.conf /etc/nginx/nginx.conf
COPY http_server.conf /etc/nginx/conf.d/default.conf
COPY init.sh /docker-entrypoint.d/40-init-config.sh
