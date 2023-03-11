#!/usr/bin/env bash
set -euo pipefail

GITHUB_TOKEN="${GITHUB_TOKEN:?Error: GITHUB_TOKEN must be set}"

JSON_PAYLOAD=$(cat <<-END
{
  "ref": "$(git rev-parse --abbrev-ref HEAD)",
  "inputs":
  {
    "pullNumber": "$(echo $APP_ID)",
    "imageTag": "$(echo $IMAGE_TAG)",
    "repoName": "$(echo $REPO)",
    "chartPath": "$(echo $CHART_PATH)"
  }
}
END
)

curl -L -X POST -d "$JSON_PAYLOAD" \
  -H "authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/atrakic/argocd-previews/actions/workflows/create.yml/dispatches

# https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28#create-a-workflow-dispatch-event
