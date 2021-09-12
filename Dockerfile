FROM nginx:alpine

RUN set -e \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache bash iproute2 busybox-extras \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && mkdir -p /opt/download \
    && cd /opt/download \
    && wget https://download.jumpserver.org/public/jumpserver-client.dmg \
    && wget https://download.jumpserver.org/public/jumpserver-client.msi.zip \
    && wget https://download.jumpserver.org/public/Microsoft_Remote_Desktop_10.6.7_installer.pkg

COPY release/lina /opt/lina
COPY release/luna /opt/luna
COPY nginx.conf /etc/nginx/nginx.conf
COPY http_server.conf /etc/nginx/conf.d/default.conf
