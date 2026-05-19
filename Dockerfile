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
    && apt-get purge -y wget \
        curl \
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
COPY nginx.conf /etc/nginx/nginx.conf
COPY includes /etc/nginx/includes
COPY http_server.conf /etc/nginx/conf.d/http_server.conf
COPY init.sh /docker-entrypoint.d/40-init-config.sh
