FROM nginx:alpine
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY release/lina /opt/lina
COPY release/luna /opt/luna
COPY nginx.conf /etc/nginx/nginx.conf
COPY http_server.conf /etc/nginx/conf.d/default.conf
