#!/usr/bin/env bash
set -euo pipefail

APP_ID="${APP_ID:?Error: APP_ID must be set}"
REPO="${REPO:?Error: REPO must be set}"
IMAGE_TAG="${IMAGE_TAG:?Error: IMAGE_TAG must be set}"
CHART_PATH="${CHART_PATH:?Error: CHART_PATH must be set}"

HOST="${HOST:-test.127.0.0.1.nip.io}"       # If variable not set or null, set it to default
export HOST

YAML=$(echo "$APP_ID" | sed -e 's#/#-#g')   # rewrite
cat preview.yaml | \
  kyml tmpl -e HOST -e APP_ID -e IMAGE_TAG -e REPO -e CHART_PATH\
  | tee charts/previews/templates/"$YAML".yml
