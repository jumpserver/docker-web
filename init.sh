#!/bin/bash
#

function config_nginx() {
  config_file=$1
  if [ ! -f "${config_file}" ]; then
    echo "config file ${config_file} not found"
    exit 1
  fi

  if [ -z "${HTTP_PORT}" ]; then
    HTTP_PORT=80
  fi
  if [ -z "${USE_LB}" ]; then
    USE_LB=1
  fi

  if [ "${USE_IPV6}" == "1" ]; then
    sed -i "s@# listen \[::\]:80;@listen \[::\]:80;@g" "${config_file}"
    if [ -f "/etc/nginx/conf.d/default.conf" ]; then
      sed -i "s@# listen \[::\]:51980;@listen \[::\]:51980;@g" /etc/nginx/conf.d/default.conf
    fi
  fi

  if [ "${HTTP_PORT}" != "80" ]; then
    sed -i "s@listen 80;@listen ${HTTP_PORT};@g" "${config_file}"
    if [ "${USE_IPV6}" == "1" ]; then
      sed -i "s@listen \[::\]:80;@listen \[::\]:${HTTP_PORT};@g" "${config_file}"
    fi
  fi

  if [ -n "${SERVER_NAME}" ]; then
    SERVER_NAME=$(echo "$SERVER_NAME" | sed 's/,/ /g; s/ *$//')
    sed -i "s@# server_name .*;@server_name ${SERVER_NAME};@g" "${config_file}"
  fi

  if [ -n "${CLIENT_MAX_BODY_SIZE}" ]; then
    sed -i "s@client_max_body_size .*;@client_max_body_size ${CLIENT_MAX_BODY_SIZE};@g" /etc/nginx/conf.d/*.conf
  fi

  if [ "${USE_LB}" == "1" ]; then
    sed -i 's@proxy_set_header X-Forwarded-For .*;@proxy_set_header X-Forwarded-For $remote_addr;@g' "${config_file}"
  else
    sed -i 's@proxy_set_header X-Forwarded-For .*;@proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;@g' "${config_file}"
  fi
}

# helm-charts mount
# https://github.com/jumpserver/helm-charts/blob/main/charts/jumpserver/templates/web/deployment-nginx.yaml#L60
function config_helm() {
  rm -f /etc/nginx/conf.d/*.conf
  config_file=/etc/nginx/conf.d/jms.conf

  cp -f /etc/nginx/sites-enabled/jms.conf "${config_file}"

  config_nginx "${config_file}"

  if [ -f "/etc/init.d/cron" ]; then
    /etc/init.d/cron start
  fi
}

# Installer mount
# https://github.com/jumpserver/installer/blob/dev/compose/docker-compose-lb.yml#L14
function config_http() {
  config_file=/etc/nginx/conf.d/http_server.conf
  if [ -f "${config_file}" ]; then
    rm -f "${config_file}"
  fi
  cp -f /etc/nginx/sites-enabled/http_server.conf "${config_file}"

  config_nginx "${config_file}"
}

function config_https() {
  config_file=/etc/nginx/conf.d/https_server.conf
  if [ -f "${config_file}" ]; then
    rm -f "${config_file}"
  fi
  cp -f /etc/nginx/sites-enabled/https_server.conf "${config_file}"

  config_nginx "${config_file}"

  if [ -z "${HTTPS_PORT}" ]; then
    HTTPS_PORT=443
  fi

  sed -i "s@server web[:0-9]*@server localhost:51980@g" "${config_file}"

  if [ "${USE_IPV6}" == "1" ]; then
    sed -i "s@# listen \[::\]:443@listen \[::\]:443@g" "${config_file}"
  fi

  if [ "${HTTPS_PORT}" != "443" ]; then
    sed -i "s@listen 443@listen ${HTTPS_PORT}@g" "${config_file}"
    sed -i "s@https://\$server_name\$request_uri;@https://\$server_name:${HTTPS_PORT}\$request_uri;@g" "${config_file}"
    if [ "${USE_IPV6}" == "1" ]; then
      sed -i "s@listen \[::\]:443@listen \[::\]:${HTTPS_PORT}@g" "${config_file}"
    fi
  fi

  if [ -n "${SSL_CERTIFICATE}" ] && [ -f "/etc/nginx/cert/${SSL_CERTIFICATE}" ]; then
    sed -i "s@ssl_certificate .*;@ssl_certificate cert/${SSL_CERTIFICATE};@g" "${config_file}"
  fi
  if [ -n "${SSL_CERTIFICATE_KEY}" ] && [ -f "/etc/nginx/cert/${SSL_CERTIFICATE_KEY}" ]; then
    sed -i "s@ssl_certificate_key .*;@ssl_certificate_key cert/${SSL_CERTIFICATE_KEY};@g" "${config_file}"
  fi
  if [ -n "${CLIENT_MAX_BODY_SIZE}" ]; then
    sed -i "s@client_max_body_size .*;@client_max_body_size ${CLIENT_MAX_BODY_SIZE};@g" "${config_file}"
  fi
}

# config components
function config_components() {
  if [ "${CORE_ENABLED}" == "0" ]; then
    mv /etc/nginx/includes/core.conf /etc/nginx/includes/core.conf.disabled
  fi

  if [ "${KOKO_ENABLED}" == "0" ]; then
    mv /etc/nginx/includes/koko.conf /etc/nginx/includes/koko.conf.disabled
  fi

  if [ "${LION_ENABLED}" == "0" ]; then
    mv /etc/nginx/includes/lion.conf /etc/nginx/includes/lion.conf.disabled
  fi

  if [ "${CHEN_ENABLED}" == "0" ]; then
    mv /etc/nginx/includes/chen.conf /etc/nginx/includes/chen.conf.disabled
  fi

  if [ "${USE_XPACK}" == "1" ]; then
    if [ "${RAZOR_ENABLED}" != "0" ]; then
      mv /etc/nginx/includes/razor.conf.disabled /etc/nginx/includes/razor.conf
    fi
  fi
}

function copy_versions_to_core() {
  if [[ -f "/opt/download/versions.txt" && -d "/opt/jumpserver/data/"  ]]; then
    cp -f /opt/download/versions.txt /opt/jumpserver/data/version.txt
  fi
}

function main() {
  if [ -f "/etc/nginx/sites-enabled/jms.conf" ]; then
    config_helm
    exit 0
  fi

  if [ -f "/etc/nginx/sites-enabled/https_server.conf" ]; then
    config_https
  else
    config_http
  fi
  config_components

  if [ -f "/etc/init.d/cron" ]; then
    /etc/init.d/cron start
  fi

  copy_versions_to_core
}

main
