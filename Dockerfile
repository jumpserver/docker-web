ARG VERSION=dev
FROM jumpserver/lina:${VERSION} AS lina
FROM jumpserver/luna:${VERSION} AS luna

FROM nginx:1.31-trixie
ARG TARGETARCH

ARG APT_MIRROR=http://deb.debian.org

ARG TOOLS="                           \
        ca-certificates               \
        wget                          \
        logrotate                     \
        "

RUN set -ex \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && sed -i "s@http://.*.debian.org@${APT_MIRROR}@g" /etc/apt/sources.list.d/debian.sources\
    && apt-get update > /dev/null \
    && apt-get -y upgrade \
    && apt-get -y install --no-install-recommends ${TOOLS} \
    && wget https://github.com/jumpserver-dev/healthcheck/releases/latest/download/check_linux_${TARGETARCH}.deb \
    && dpkg -i check_linux_${TARGETARCH}.deb \
    && apt-get purge -y curl \
        nginx-module-xslt \
        nginx-module-njs \
        libxml2 \
        libxslt1.1 \
        libgd3 \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -f check_linux_${TARGETARCH}.deb \
    && rm -f /etc/nginx/conf.d/default.conf

WORKDIR /opt

COPY --from=lina /opt/lina /opt/lina
COPY --from=luna /opt/luna /opt/luna
COPY versions.txt /opt/download/versions.txt
COPY client-version.txt /opt/download/client-version.txt
COPY nginx.conf /etc/nginx/nginx.conf
COPY includes /etc/nginx/includes
COPY example /etc/nginx/example
COPY default.conf /etc/nginx/conf.d/default.conf
COPY luna-bfcache.conf /etc/nginx/conf.d/luna-bfcache.conf
COPY https_server.conf /etc/nginx/sites-enabled/https_server.conf
COPY init.sh /docker-entrypoint.d/40-init-config.sh

# Terminal freeze protection: hold a Web Lock per open terminal websocket so
# Chromium's background tab freezing exempts Luna pages, and keep Luna HTML
# out of the Back-Forward Cache (see luna-bfcache.conf). The guard is a
# plain synchronous script injected before the Luna app boots.
COPY utils/luna-terminal-session-guard.js /tmp/luna-terminal-session-guard.js
COPY utils/install-luna-terminal-guard.sh /tmp/install-luna-terminal-guard.sh
RUN sh /tmp/install-luna-terminal-guard.sh \
    && rm /tmp/luna-terminal-session-guard.js /tmp/install-luna-terminal-guard.sh
