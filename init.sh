#!/bin/bash
#

if [ -n "${CLIENT_MAX_BODY_SIZE}" ]; then
  sed -i "s@client_max_body_size .*;@client_max_body_size ${CLIENT_MAX_BODY_SIZE};@g" /etc/nginx/conf.d/default.conf
fi
