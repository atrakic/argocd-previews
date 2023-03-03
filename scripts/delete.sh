#!/usr/bin/env bash
set -euo pipefail

APP_ID="${APP_ID:?Error: APP_ID must be set}"
YAML=$(echo $APP_ID | sed -e 's#/#-#g')
rm -rf charts/previews/templates/"$YAML".yml
