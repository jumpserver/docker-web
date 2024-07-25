ARG VERSION
FROM jumpserver/lina:${VERSION} AS lina
FROM jumpserver/luna:${VERSION} AS luna
FROM jumpserver/web-static:20240725_093508 AS static

FROM nginx:1.24-bullseye
ARG TARGETARCH

ARG DEPENDENCIES="                    \
        ca-certificates               \
        logrotate                     \
        wget"

ARG APT_MIRROR=http://deb.debian.org
RUN set -ex \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache \
    && sed -i "s@http://.*.debian.org@${APT_MIRROR}@g" /etc/apt/sources.list \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get update \
    && apt-get install -y --no-install-recommends ${DEPENDENCIES} \
    && echo "no" | dpkg-reconfigure dash \
    && rm -f /var/log/nginx/*.log \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

COPY --from=lina /opt/lina /opt/lina
COPY --from=luna /opt/luna /opt/luna
COPY --from=static /usr/local/bin /usr/local/bin
COPY --from=static /tmp/opt/download/versions.txt /opt/download/versions.txt
COPY nginx.conf /etc/nginx/nginx.conf
COPY includes /etc/nginx/includes
COPY default.conf /etc/nginx/conf.d/default.conf
COPY http_server.conf /etc/nginx/sites-enabled/http_server.conf
COPY init.sh /docker-entrypoint.d/40-init-config.sh
