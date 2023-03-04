#!/usr/bin/env bash
set -o errexit
curl -fisk localhost:80 -H "Host: $HOST"
