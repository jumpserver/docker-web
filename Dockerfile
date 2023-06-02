FROM nginx:1.24

ARG TARGETARCH
ARG APT_MIRROR=http://mirrors.ustc.edu.cn

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=web \
    sed -i "s@http://.*.debian.org@${APT_MIRROR}@g" /etc/apt/sources.list \
    && rm -f /etc/cron.daily/apt-compat \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get update \
    && apt-get install -y --no-install-recommends wget vim logrotate locales \
    && echo "no" | dpkg-reconfigure dash \
    && echo "zh_CN.UTF-8" | dpkg-reconfigure locales \
    && rm -f /var/log/nginx/*.log \
    && rm -rf /var/lib/apt/lists/*

ARG DOWNLOAD_URL=https://download.jumpserver.org
ARG PLAY_VERSION=1.1.0-1

# 下载 player 脚本
WORKDIR /opt/player
RUN set -ex \
    && wget -q ${DOWNLOAD_URL}/public/glyptodon-enterprise-player-${PLAY_VERSION}.tar.gz \
    && tar -xf glyptodon-enterprise-player-${PLAY_VERSION}.tar.gz -C /opt/player --strip-components 1 \
    && rm -f glyptodon-enterprise-player-${PLAY_VERSION}.tar.gz

# 下载公共的客户端
WORKDIR /opt/download/public
ARG Client_VERSION=v1.1.8
ARG MRD_VERSION=10.6.7
ARG VIDEO_PLAYER_VERSION=0.1.5

RUN set -ex \
    && mkdir -p /etc/nginx/sites-enabled \
    && wget -qO  JumpServer-Client-Installer-x86_64.msi ${DOWNLOAD_URL}/public/JumpServer-Client-Installer-${Client_VERSION}-x86_64.msi \
    && wget -qO  JumpServer-Client-Installer-amd64.dmg ${DOWNLOAD_URL}/public/JumpServer-Client-Installer-${Client_VERSION}-amd64.dmg \
    && wget -qO  JumpServer-Client-Installer-arm64.dmg ${DOWNLOAD_URL}/public/JumpServer-Client-Installer-${Client_VERSION}-arm64.dmg \
    && wget -qO  JumpServer-Client-Installer-amd64.run ${DOWNLOAD_URL}/public/JumpServer-Client-Installer-${Client_VERSION}-amd64.run \
    && wget -qO  JumpServer-Client-Installer-arm64.run ${DOWNLOAD_URL}/public/JumpServer-Client-Installer-${Client_VERSION}-arm64.run \
    && wget -qO  JumpServer-Video-Player.dmg ${DOWNLOAD_URL}/public/JumpServer.Video.Player-${VIDEO_PLAYER_VERSION}.dmg \
    && wget -qO  JumpServer-Video-Player.exe ${DOWNLOAD_URL}/public/JumpServer.Video.Player.Setup.${VIDEO_PLAYER_VERSION}.exe \
    && wget -qO  OpenSSH-Win64.msi ${DOWNLOAD_URL}/public/OpenSSH-Win64.msi \
    && wget -q ${DOWNLOAD_URL}/public/Microsoft_Remote_Desktop_${MRD_VERSION}_installer.pkg

# 下载 applets 的相关依赖
WORKDIR /opt/download/applets
ARG TINKER_VERSION=v0.0.9
ARG PYTHON_VERSION=3.10.8
ARG CHROMIUM_VERSION=1100786
ARG DBEAVER_VERSION=22.3.4

RUN set -ex \
    && wget -qO navicat161_premium_en_x64.exe ${DOWNLOAD_URL}/public/navicat161_premium_en_x64.exe \
    && wget -qO chromedriver_win32.zip ${DOWNLOAD_URL}/chromium-browser-snapshots/Win_x64/${CHROMIUM_VERSION}/Win_x64_${CHROMIUM_VERSION}_chromedriver_win32.zip \
    && wget -qO chrome-win.zip ${DOWNLOAD_URL}/chromium-browser-snapshots/Win_x64/${CHROMIUM_VERSION}/Win_x64_${CHROMIUM_VERSION}_chrome-win.zip \
    && wget -qO Tinker_Installer.exe ${DOWNLOAD_URL}/public/Tinker_Installer_${TINKER_VERSION}.exe \
    && wget -qO dbeaver-patch.msi ${DOWNLOAD_URL}/public/dbeaver-patch-${DBEAVER_VERSION}-x86_64-setup.msi \
    && wget -q ${DOWNLOAD_URL}/public/dbeaver-ce-${DBEAVER_VERSION}-x86_64-setup.exe \
    && wget -q ${DOWNLOAD_URL}/public/python-${PYTHON_VERSION}-amd64.exe

WORKDIR /opt/download/
COPY release/lina /opt/lina
COPY release/luna /opt/luna
COPY release/applets /opt/download/applets
COPY nginx.conf /etc/nginx/nginx.conf
COPY http_server.conf /etc/nginx/conf.d/default.conf
COPY init.sh /docker-entrypoint.d/40-init-config.sh
