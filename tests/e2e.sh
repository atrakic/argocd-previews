#!/usr/bin/env bash
set -euo pipefail

echo "Waiting for pods to all come up"
until ! kubectl get po -A | grep ContainerCreating; do
    echo "Pods still creating"
    sleep 5
done

curl -fisk localhost:80 -H "Host: $HOST"
