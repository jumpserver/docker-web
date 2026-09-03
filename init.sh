#!/bin/bash
#
function config_nginx() {
  config_file=$1
  if [ ! -f "${config_file}" ]; then
    echo "config file ${config_file} not found"
    exit 1
  fi

  if [ "${USE_IPV6}" == "1" ]; then
    sed -i "s@# listen \[::\]:80;@listen \[::\]:80;@g" "${config_file}"
    if [ -f "/etc/nginx/conf.d/default.conf" ]; then
      sed -i "s@# listen \[::\]:51980;@listen \[::\]:51980;@g" /etc/nginx/conf.d/default.conf
    fi
  fi

  if [ -n "${SERVER_NAME}" ]; then
    SERVER_NAME=$(echo "$SERVER_NAME" | sed 's/,/ /g; s/ *$//')
    sed -i "s@# server_name .*;@server_name ${SERVER_NAME};@g" "${config_file}"
  fi

  if [ -n "${CLIENT_MAX_BODY_SIZE}" ]; then
    sed -i "s@client_max_body_size .*;@client_max_body_size ${CLIENT_MAX_BODY_SIZE};@g" /etc/nginx/conf.d/*.conf
  fi

  # Only an explicit USE_LB=0 means there is a trusted proxy in front of us.
  # Otherwise this server is the trust boundary and must discard client-supplied
  # X-Forwarded-For values.
  if [ "${USE_LB:-1}" == "0" ]; then
    sed -i 's@proxy_set_header X-Forwarded-For .*;@proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;@g' "${config_file}"
  else
    sed -i 's@proxy_set_header X-Forwarded-For .*;@proxy_set_header X-Forwarded-For $remote_addr;@g' "${config_file}"
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

function config_certificate() {
  cert_dir=/etc/nginx/cert
  example_dir=/etc/nginx/example
  default_cert_name=server.crt
  default_key_name=server.key
  cert_name=${SSL_CERTIFICATE:-${default_cert_name}}
  key_name=${SSL_CERTIFICATE_KEY:-${default_key_name}}
  cert_file=${cert_dir}/${cert_name}
  key_file=${cert_dir}/${key_name}

  mkdir -p "${cert_dir}"

  if [[ ! -f "${cert_file}" || ! -f "${key_file}" ]]; then
    if [[ -n "${SSL_CERTIFICATE}" || -n "${SSL_CERTIFICATE_KEY}" ]]; then
      echo "Warning: SSL certificate or private key not found: ${cert_file}, ${key_file}"
      echo "Falling back to the default certificate pair: ${default_cert_name}, ${default_key_name}"
    fi

    cert_name=${default_cert_name}
    key_name=${default_key_name}
    cert_file=${cert_dir}/${cert_name}
    key_file=${cert_dir}/${key_name}
  fi

  if [[ ! -f "${cert_file}" && ! -f "${key_file}" ]]; then
    cp -f "${example_dir}/example.crt" "${cert_file}"
    cp -f "${example_dir}/example.key" "${key_file}"
  elif [[ ! -f "${cert_file}" || ! -f "${key_file}" ]]; then
    echo "SSL certificate and private key must both exist: ${cert_file}, ${key_file}"
    exit 1
  fi

  chmod 600 "${cert_file}" "${key_file}"
}

function config_https() {
  config_file=/etc/nginx/conf.d/https_server.conf
  if [ -f "${config_file}" ]; then
    rm -f "${config_file}"
  fi
  cp -f /etc/nginx/sites-enabled/https_server.conf "${config_file}"

  config_certificate
  config_nginx "${config_file}"

  sed -i "s@server web:.*;@server localhost:51980;@g" "${config_file}"
  if [[ -n "${HTTPS_PORT}" && "${HTTPS_PORT}" != "0" ]]; then
    if [ "${HTTPS_PORT}" == "443" ]; then
      redirect_url='https://$host$request_uri'
    else
      redirect_url="https://\$host:${HTTPS_PORT}\$request_uri"
    fi
    sed -i "s@  # HTTPS_REDIRECT@  return 307 ${redirect_url};@g" "${config_file}"
  fi

  if [ "${USE_IPV6}" == "1" ]; then
    sed -i "s@# listen \[::\]:443 ssl;@listen [::]:443 ssl;@g" "${config_file}"
  fi

  sed -i "s@ssl_certificate .*;@ssl_certificate cert/${cert_name};@g" "${config_file}"
  sed -i "s@ssl_certificate_key .*;@ssl_certificate_key cert/${key_name};@g" "${config_file}"
  if [ -n "${CLIENT_MAX_BODY_SIZE}" ]; then
    sed -i "s@client_max_body_size .*;@client_max_body_size ${CLIENT_MAX_BODY_SIZE};@g" "${config_file}"
  fi
}

function safe_move() {
  if [ -f "$1" ]; then
    mv "$1" "$2"
  fi
}

# config components
function config_components() {
  if [ "${CORE_ENABLED}" == "0" ]; then
    safe_move /etc/nginx/includes/core.conf /etc/nginx/includes/core.conf.disabled
  fi

  if [ "${CHAT_AI_SERVICE_ENABLED}" == "1" ]; then
    safe_move /etc/nginx/includes/chat_ai.conf.disabled /etc/nginx/includes/chat_ai.conf
  else
    safe_move /etc/nginx/includes/chat_ai.conf /etc/nginx/includes/chat_ai.conf.disabled
  fi

  if [ "${KOKO_ENABLED}" == "0" ]; then
    safe_move /etc/nginx/includes/koko.conf /etc/nginx/includes/koko.conf.disabled
  fi

  if [ "${CHEN_ENABLED}" == "0" ]; then
    safe_move /etc/nginx/includes/chen.conf /etc/nginx/includes/chen.conf.disabled
  fi

  if [ "${USE_XPACK}" == "1" ]; then
    safe_move /etc/nginx/includes/jdmc.conf.disabled /etc/nginx/includes/jdmc.conf
  else
    safe_move /etc/nginx/includes/jdmc.conf /etc/nginx/includes/jdmc.conf.disabled
  fi

  if [[ "${USE_XPACK}" == "1" && "${RAZOR_ENABLED}" != "0" ]]; then
    safe_move /etc/nginx/includes/razor.conf.disabled /etc/nginx/includes/razor.conf
  fi
}

function copy_versions_to_core() {
  if [[ -f "/opt/download/versions.txt" && -d "/opt/jumpserver/data/"  ]]; then
    cp -f /opt/download/versions.txt /opt/jumpserver/data/version.txt
    if [[ -f "/opt/download/client-version.txt" ]]; then
      cat /opt/download/client-version.txt >> /opt/jumpserver/data/version.txt
    fi
  fi
}

function config_gzip() {
  if [[ "${GZIP}" == "off" ]]; then
    sed -i "s@gzip .*;@gzip ${GZIP};@g" /etc/nginx/nginx.conf
  fi
}

function main() {
  if [ -f "/etc/nginx/sites-enabled/jms.conf" ]; then
    config_helm
    exit 0
  fi

  config_https
  config_components

  if [ -f "/etc/init.d/cron" ]; then
    /etc/init.d/cron start
  fi

  copy_versions_to_core
  config_gzip
}

main
