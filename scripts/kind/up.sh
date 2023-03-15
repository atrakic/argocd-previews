#!/usr/bin/env bash
set -o errexit

# Adapted from:
# https://raw.githubusercontent.com/kubernetes-sigs/kind/main/site/static/examples/kind-with-registry.sh
# https://gist.github.com/diafour/13cef191b7cf39543393d310dd6353a0
# https://github.com/kubernetes-sigs/kind/issues/1213

# create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

## Push usage:
# docker pull gcr.io/google-samples/hello-app:1.0
# docker tag gcr.io/google-samples/hello-app:1.0 localhost:5001/hello-app:1.0
# docker push localhost:5001/hello-app:1.0
# kubectl create deployment hello-server --image=localhost:5001/hello-app:1.0
curl -k -X GET http://localhost:${reg_port}/v2/_catalog

# create a cluster with the local registry enabled in containerd
kind create cluster --config config/kind.yaml --wait 60s || true

# connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
