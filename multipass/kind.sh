#!/bin/bash

brew install gsed wget || true

# Podman IP configuration
INSTANCE_NAME="podman"

IP=$(multipass info $INSTANCE_NAME | grep IPv4: | cut -d ':' -f2 | tr -ds ' ' '')

IP_CONFIG_EXISTS=$(cat /private/etc/hosts | grep -c "$IP")
if [[ $IP_CONFIG_EXISTS -eq 0 ]]; then
  echo "$IP $INSTANCE_NAME" | sudo tee -a /private/etc/hosts
fi


