#!/usr/bin/env bash
set -o errexit

NS=argocd
kubectl create namespace "$NS" || true
#kubectl -n "$NS" apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n "$NS" apply -f config/argocd-noauth/install.yaml

kubectl wait --for=condition=available deployment -l "app.kubernetes.io/name=argocd-server" -n "$NS" --timeout=600s
kubectl wait --for=condition=available deployment argocd-repo-server -n "$NS" --timeout=60s
kubectl wait --for=condition=available deployment argocd-dex-server -n "$NS" --timeout=60s
