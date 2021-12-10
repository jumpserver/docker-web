#!/bin/bash
#

if [ -f "/etc/nginx/sites-enabled/jumpserver.conf" ]; then
  cp -rf /etc/nginx/sites-enabled/jumpserver.conf /etc/nginx/conf.d/default.conf
fi

if [ "${USE_IPV6}" == "1" ]; then
  sed -i 's@# listen \[::\]:80@listen \[::\]:80@g' /etc/nginx/conf.d/default.conf
  sed -i 's@# listen \[::\]:443@listen \[::\]:443@g' /etc/nginx/conf.d/default.conf
fi

if [ -n "${CLIENT_MAX_BODY_SIZE}" ]; then
  sed -i "s@client_max_body_size .*;@client_max_body_size ${CLIENT_MAX_BODY_SIZE};@g" /etc/nginx/conf.d/default.conf
fi
