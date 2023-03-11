# argocd-previews

> This repo populates [helm chart](charts/previews) with Argo CD Application manifests.

[![e2e](https://github.com/atrakic/argocd-previews/workflows/e2e/badge.svg)](https://github.com/atrakic/argocd-previews/actions)

## Requirements
- Docker

### Usage

```shell
$ make

Usage:
  make <target>
  all                 Do all
  setup               Setup kinD with ArgoCD + Nginx Ingress
  status              Status
  port_forward        ArgoCD Port forward
  login               ArgoCD Login
  deploy              Deploy a local helm chart with ArgoCD Application previews
  e2e                 E2e local helm chart
  e2e-remote-chart    E2e remote helm chart
  sync                Sync previews
  clean               Clean
```

## Triggering pipelines
- [Create](https://github.com/atrakic/argocd-previews/blob/master/.github/workflows/create.yml)
- [Delete](https://github.com/atrakic/argocd-previews/blob/master/.github/workflows/delete.yml)

## Credits
* [Environments Based On Pull Requests (PRs): Using Argo CD To Apply GitOps Principles On Previews](https://youtu.be/cpAaI8p4R60)
