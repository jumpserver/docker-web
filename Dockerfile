ARG VERSION
FROM jumpserver/lina:${VERSION} AS lina
FROM jumpserver/luna:${VERSION} AS luna
FROM jumpserver/web-static:20240725_084903 AS static

FROM nginx:1.24-bullseye
ARG TARGETARCH

WORKDIR /opt

COPY --from=lina /opt/lina /opt/lina
COPY --from=luna /opt/luna /opt/luna
COPY --from=static /usr/local/bin/check /usr/local/bin/check
COPY versions.txt /opt/download/versions.txt
COPY nginx.conf /etc/nginx/nginx.conf
COPY includes /etc/nginx/includes
COPY default.conf /etc/nginx/conf.d/default.conf
COPY http_server.conf /etc/nginx/sites-enabled/http_server.conf
COPY init.sh /docker-entrypoint.d/40-init-config.sh
