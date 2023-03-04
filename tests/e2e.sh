#!/usr/bin/env bash
set -euo pipefail
curl -fisk localhost:80 -H "Host: $HOST"
