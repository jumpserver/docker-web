ARG VERSION
FROM jumpserver/lina:${VERSION} AS lina
FROM jumpserver/luna:${VERSION} AS luna

FROM nginx:1.24-alpine
ARG TARGETARCH

ARG CHECK_VERSION=v1.0.2
RUN wget https://github.com/jumpserver-dev/healthcheck/releases/download/${CHECK_VERSION}/check-${CHECK_VERSION}-linux-${TARGETARCH}.tar.gz \
    && tar -xf check-${CHECK_VERSION}-linux-${TARGETARCH}.tar.gz \
    && mv check /usr/local/bin/ \
    && chown root:root /usr/local/bin/check \
    && chmod 755 /usr/local/bin/check \
    && rm -f check-${CHECK_VERSION}-linux-${TARGETARCH}.tar.gz

WORKDIR /opt

COPY --from=lina /opt/lina /opt/lina
COPY --from=luna /opt/luna /opt/luna
COPY versions.txt /opt/download/versions.txt
COPY nginx.conf /etc/nginx/nginx.conf
COPY includes /etc/nginx/includes
COPY default.conf /etc/nginx/conf.d/default.conf
COPY http_server.conf /etc/nginx/sites-enabled/http_server.conf
COPY init.sh /docker-entrypoint.d/40-init-config.sh
