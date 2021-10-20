#!/bin/bash
#

if [ -f "/etc/nginx/sites-enabled/jumpserver.conf" ]; then
  cp -rf /etc/nginx/sites-enabled/jumpserver.conf /etc/nginx/conf.d/default.conf
fi

if [ -n "${CLIENT_MAX_BODY_SIZE}" ]; then
  sed -i "s@client_max_body_size .*;@client_max_body_size ${CLIENT_MAX_BODY_SIZE};@g" /etc/nginx/conf.d/default.conf
fi
