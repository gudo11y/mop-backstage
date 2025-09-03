#!/bin/bash

set -o errexit

echo "Setting up Tilt for $1"

# desired profile name; default is ""
MINIKUBE_PROFILE_NAME="${MINIKUBE_PROFILE_NAME:-minikube}"

reg_name='host.minikube.internal'
reg_port='5000'f

# create registry container unless it already exists
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

reg_host="$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "${reg_name}")"
echo "Registry Host: ${reg_host}"

# create a cluster
minikube start -p "$MINIKUBE_PROFILE_NAME" --driver=docker --container-runtime=containerd

# patch the container runtime
# this is the most annoying sed expression i've ever had to write
minikube ssh sudo sed "\-i" "s,\\\[plugins.cri.registry.mirrors\\\],[plugins.cri.registry.mirrors]\\\n\ \ \ \ \ \ \ \ [plugins.cri.registry.mirrors.\\\"localhost:${reg_port}\\\"]\\\n\ \ \ \ \ \ \ \ \ \ endpoint\ =\ [\\\"http://${reg_host}:5000\\\"]," /etc/containerd/config.toml

# restart the container runtime
minikube ssh sudo systemctl restart containerd

# document the registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://github.com/tilt-dev/minikube-local"
EOF

(cd tanka && jb install)

(cd "tanka/environments/$1" && tk tool charts vendor)

mkdir -p .tilt && touch ".tilt/$1.yaml"
