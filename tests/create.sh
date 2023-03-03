#!/usr/bin/env bash
set -o errexit

export APP_ID="pr-0000"
export REPO="atrakic/argocd-previews"
export IMAGE_TAG="v0.0.2"
export CHART_PATH="charts/demo"
#export HOST="${APP_ID}.$(curl -sSL ifconfig.co).nip.io"

./scripts/create.sh

PAYLOAD=$(cat <<-END
{
  "ref": "$(git rev-parse --abbrev-ref HEAD)",
  "inputs":
  {
    "pullNumber": "$(echo $APP_ID)",
    "imageTag": "$(git rev-parse --short HEAD)",
    "repoName": "$(echo $REPO)",
    "chartPath": "$(echo $CHART_PATH)"
  }
}
END
)

#jq -r "$PAYLOAD"
curl -L -X POST -d "$PAYLOAD" \
  -H "authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/atrakic/argocd-previews/actions/workflows/create.yml/dispatches

# https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28#create-a-workflow-dispatch-event
