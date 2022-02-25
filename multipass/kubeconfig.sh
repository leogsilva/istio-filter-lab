#!/bin/bash

INSTANCE_NAME="podman"

K3S_IP=$(multipass info $INSTANCE_NAME | grep IPv4 | awk '{print $2}')
multipass exec $INSTANCE_NAME sudo cat /etc/rancher/k3s/k3s.yaml > ../.kubeconfig
sed -i '' "s/127.0.0.1/${K3S_IP}/" ../.kubeconfig