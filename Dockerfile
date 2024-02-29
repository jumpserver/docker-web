ARG VERSION
FROM registry.fit2cloud.com/jumpserver/web-static:v1.0.7 as static
FROM registry.fit2cloud.com/jumpserver/lina:${VERSION} as lina
FROM registry.fit2cloud.com/jumpserver/luna:${VERSION} as luna
FROM registry.fit2cloud.com/jumpserver/applets:${VERSION} as applets

FROM nginx:1.24-bullseye
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

WORKDIR /opt

COPY --from=static /opt /opt
COPY --from=lina /opt/lina /opt/lina
COPY --from=luna /opt/luna /opt/luna
COPY --from=applets /opt/applets /opt/download/applets
COPY nginx.conf /etc/nginx/nginx.conf
COPY includes /etc/nginx/includes
COPY default.conf /etc/nginx/conf.d/default.conf
COPY http_server.conf /etc/nginx/sites-enabled/http_server.conf
COPY init.sh /docker-entrypoint.d/40-init-config.sh
