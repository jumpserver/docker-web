FROM nginx:stable

ARG Jmservisor_VERSION=v1.2.3
ARG Client_VERSION=v1.1.6
ARG MRD_VERSION=10.6.7
ARG VIDEO_PLAYER_VERSION=0.1.5

RUN set -e \
    && sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && apt update \
    && apt-get install -y iproute2 wget vim \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && mkdir -p /opt/download /etc/nginx/sites-enabled \
    && cd /opt/download \
    && wget -q https://download.jumpserver.org/public/Microsoft_Remote_Desktop_${MRD_VERSION}_installer.pkg \
    && wget -qO /opt/download/Jmservisor.msi https://download.jumpserver.org/public/Jmservisor-${Jmservisor_VERSION}.msi \
    && wget -qO /opt/download/JumpServer-Client-Installer-x86_64.msi https://download.jumpserver.org/public/JumpServer-Client-Installer-${Client_VERSION}-x86_64.msi \
    && wget -qO /opt/download/JumpServer-Client-Installer.dmg https://download.jumpserver.org/public/JumpServer-Client-Installer-${Client_VERSION}.dmg \
    && wget -qO /opt/download/JumpServer-Client-Installer-amd64.run https://download.jumpserver.org/public/JumpServer-Client-Installer-${Client_VERSION}-amd64.run \
    && wget -qO /opt/download/JumpServer-Client-Installer-arm64.run https://download.jumpserver.org/public/JumpServer-Client-Installer-${Client_VERSION}-arm64.run \
    && wget -qO /opt/download/JumpServer-Video-Player.dmg https://jms-pkg.oss-cn-beijing.aliyuncs.com/public/JumpServer.Video.Player-${VIDEO_PLAYER_VERSION}.dmg \
    && wget -qO /opt/download/JumpServer-Video-Player.exe https://jms-pkg.oss-cn-beijing.aliyuncs.com/public/JumpServer.Video.Player.Setup.${VIDEO_PLAYER_VERSION}.exe \
    && rm -rf /var/log/nginx/*.log \
    && rm -rf /var/lib/apt/lists/*

COPY release/lina /opt/lina
COPY release/luna /opt/luna
COPY nginx.conf /etc/nginx/nginx.conf
COPY http_server.conf /etc/nginx/conf.d/default.conf
COPY init.sh /docker-entrypoint.d/40-init-config.sh
