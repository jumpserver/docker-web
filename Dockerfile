FROM nginx:stable

ARG Jmservisor_VERSION=v1.2.3
ARG Client_VERSION=v1.1.3
ARG MRD_VERSION=10.6.7

RUN set -e \
    && sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && apt update \
    && apt-get install -y iproute2 wget vim \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && mkdir -p /opt/download/putty/w64 /opt/download/putty/wa64 /opt/download/putty/w32  /etc/nginx/sites-enabled \
    && cd /opt/download \
    && wget -qO /opt/download/Jmservisor.msi https://download.jumpserver.org/public/Jmservisor-${Jmservisor_VERSION}.msi \
    && wget -qO /opt/download/JumpServer-Client-Installer.msi https://download.jumpserver.org/public/JumpServer-Client-Installer-${Client_VERSION}.msi \
    && wget -qO /opt/download/JumpServer-Client-Installer.dmg https://download.jumpserver.org/public/JumpServer-Client-Installer-${Client_VERSION}.dmg \
    && wget https://download.jumpserver.org/public/Microsoft_Remote_Desktop_${MRD_VERSION}_installer.pkg \
    && wget -qO /opt/download/putty/w64/putty.exe https://the.earth.li/~sgtatham/putty/latest/w64/putty.exe \
    && wget -qO /opt/download/putty/wa64/putty.exe https://the.earth.li/~sgtatham/putty/latest/wa64/putty.exe \
    && wget -qO /opt/download/putty/w32/putty.exe https://the.earth.li/~sgtatham/putty/latest/w32/putty.exe \
    && rm -rf /var/log/nginx/*.log \
    && rm -rf /var/lib/apt/lists/*

COPY release/lina /opt/lina
COPY release/luna /opt/luna
COPY nginx.conf /etc/nginx/nginx.conf
COPY http_server.conf /etc/nginx/conf.d/default.conf
COPY init.sh /docker-entrypoint.d/40-init-config.sh
