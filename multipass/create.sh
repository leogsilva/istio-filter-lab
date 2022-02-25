#!/bin/bash

PODMAN_MODE=$1

INSTANCE_NAME="podman"
multipass set client.primary-name=$INSTANCE_NAME

multipass launch -c 4 -m 8G -d 32G -n $INSTANCE_NAME --cloud-init user-data 20.04
multipass exec $INSTANCE_NAME -- /home/ubuntu/setup-podman.sh

IP=$(multipass info $INSTANCE_NAME | grep IPv4: | cut -d ':' -f2 | tr -ds ' ' '')
if [ "$PODMAN_MODE" == "root" ]; then
  podman system connection add $INSTANCE_NAME --identity ~/.ssh/multipass  ssh://root@${IP}/run/podman/podman.sock
else
  podman system connection add $INSTANCE_NAME --identity ~/.ssh/multipass  ssh://ubuntu@${IP}/run/user/1000/podman/podman.sock
fi

IP_CONFIG_EXISTS=$(cat /private/etc/hosts | grep -c "$IP")
if [[ $IP_CONFIG_EXISTS -eq 0 ]]; then
  echo "$IP $INSTANCE_NAME" | sudo tee -a /private/etc/hosts
fi

# List of volume mounts that Docker for Desktop also mounts per default.
multipass mount /Users $INSTANCE_NAME
multipass mount /Volumes $INSTANCE_NAME
multipass mount /private $INSTANCE_NAME
multipass mount /tmp $INSTANCE_NAME
multipass mount /var/folders $INSTANCE_NAME

multipass restart $INSTANCE_NAME

multipass exec $INSTANCE_NAME -- bash -c "curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -"
./kubeconfig.sh

multipass list
echo "#######################"
podman system connection list