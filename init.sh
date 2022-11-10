#!/bin/bash
#

if [ -n "${CLIENT_MAX_BODY_SIZE}" ]; then
  sed -i "s@client_max_body_size .*;@client_max_body_size ${CLIENT_MAX_BODY_SIZE};@g" /etc/nginx/conf.d/default.conf
fi
if [ ! "${HTTPS_PORT}" ] && [ "${HTTP_PORT}" != "80" ]; then
  sed -i "s@listen 80;@listen ${HTTP_PORT};@g" /etc/nginx/conf.d/default.conf
fi
if [ ! "${HTTPS_PORT}" ] && [ "${USE_IPV6}" == "1" ]; then
  sed -i "s@# listen \[::\]:80;@listen \[::\]:${HTTP_PORT};@g" /etc/nginx/conf.d/default.conf
fi

if [ -f "/etc/nginx/sites-enabled/jumpserver.conf" ]; then
  cp -rf /etc/nginx/sites-enabled/jumpserver.conf /etc/nginx/conf.d/jumpserver.conf
  sed -i "s@listen 80;@listen 8080;@g" /etc/nginx/conf.d/default.conf
  sed -i "s@server web:80;@server web:8080;@g" /etc/nginx/conf.d/jumpserver.conf
  sed -i "s@client_max_body_size .*;@client_max_body_size ${CLIENT_MAX_BODY_SIZE};@g" /etc/nginx/conf.d/jumpserver.conf
  if [ "${HTTP_PORT}" != "80" ]; then
    sed -i "s@listen 80;@listen ${HTTP_PORT};@g" /etc/nginx/conf.d/jumpserver.conf
  fi
  if [ "$HTTPS_PORT" != "443" ]; then
    sed -i "s@listen 443@listen ${HTTPS_PORT}@g" /etc/nginx/conf.d/jumpserver.conf
    sed -i "s@https://\$server_name\$request_uri;@https://\$server_name:${HTTPS_PORT}\$request_uri;@g" /etc/nginx/conf.d/jumpserver.conf
  fi
  if [ "${USE_IPV6}" == "1" ] ; then
    sed -i "s@# listen \[::\]:80;@listen \[::\]:8080;@g" /etc/nginx/conf.d/default.conf
    sed -i "s@# listen \[::\]:80;@listen \[::\]:${HTTP_PORT};@g" /etc/nginx/conf.d/jumpserver.conf
    sed -i "s@# listen \[::\]:443@listen \[::\]:${HTTPS_PORT}@g" /etc/nginx/conf.d/jumpserver.conf
  fi
  if [ -n "${SERVER_NAME}" ]; then
    sed -i "s@# server_name .*;@server_name ${SERVER_NAME};@g" /etc/nginx/conf.d/jumpserver.conf
  fi
  if [ -n "${SSL_CERTIFICATE}" ] && [ -f "/etc/nginx/cert/${SSL_CERTIFICATE}" ]; then
    sed -i "s@ssl_certificate .*;@ssl_certificate cert/${SSL_CERTIFICATE};@g" /etc/nginx/conf.d/jumpserver.conf
  fi
  if [ -n "${SSL_CERTIFICATE_KEY}" ] && [ -f "/etc/nginx/cert/${SSL_CERTIFICATE_KEY}" ]; then
    sed -i "s@ssl_certificate_key .*;@ssl_certificate_key cert/${SSL_CERTIFICATE_KEY};@g" /etc/nginx/conf.d/jumpserver.conf
  fi
  if [ -n "${CLIENT_MAX_BODY_SIZE}" ]; then
    sed -i "s@client_max_body_size .*;@client_max_body_size ${CLIENT_MAX_BODY_SIZE};@g" /etc/nginx/conf.d/jumpserver.conf
  fi
fi

if [ -f "/etc/init.d/cron" ]; then
  /etc/init.d/cron start
fi
