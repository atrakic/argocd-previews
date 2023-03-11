MAKEFLAGS += --silent

.DEFAULT_GOAL := help

SERVER ?= 127.0.0.1:8080

# Follows naming convention from ./argocd/project.yaml
DEMO_PR ?= pr-0000-demo

all: kind setup port_forward login deploy e2e status ## Do all

kind:
	kind create cluster --config config/kind.yaml --wait 60s || true
	kind version

setup: ## Setup kinD with ArgoCD + Nginx Ingress
	kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s
	kubectl cluster-info
	scripts/argocd/up.sh
	scripts/ingress/up.sh

status: ## Status
	argocd version
	argocd --server $(SERVER) --insecure app list
	argocd --server $(SERVER) --insecure proj list
	argocd --server $(SERVER) --insecure app manifests $(DEMO_PR)

port_forward: ## ArgoCD Port forward
	scripts/argocd/port_forward.sh &
	sleep 1

login: ## ArgoCD Login
	scripts/argocd/login.sh

deploy: ## Deploy a local helm chart with ArgoCD Application previews
	kubectl apply -f argocd
	#helm upgrade --install previews ./charts/previews --set "foo.bar=True"
	argocd app sync $(DEMO_PR)

e2e: kind setup port_forward deploy ## E2e local helm chart
	echo ":: $@ :: "
	REPO="atrakic/argocd-previews" \
		IMAGE_TAG="stable-alpine" \
		CHART_PATH="charts/demo" \
		HOST="$(DEMO_PR).127.0.0.1.nip.io" \
		APP_ID="$(DEMO_PR)" scripts/create.sh
		# Commit only changes from local chart
		git add charts/previews
		git diff --name-only
		git commit --allow-empty -m "e2e: $(shell git rev-parse --short HEAD)"
		git push -u origin
		HOST="$(DEMO_PR).127.0.0.1.nip.io" tests/e2e.sh

e2e-remote-chart: ## E2e remote helm chart
	echo ":: $@ :: "
	# Example how to source remote chart via GH actions.
	# Follows naming convention from: argocd/project.yaml
	if [ -n "$(GITHUB_TOKEN)" ]; then \
		REPO="atrakic/go-static-site" \
		IMAGE_TAG="v0.0.2" \
		CHART_PATH="charts/go-static-site" \
		HOST="go-static-site.127.0.0.1.nip.io" \
		APP_ID="pr-e2e" tests/trigger_create_pr.sh; \
	fi

sync: ## Sync previews
	argocd app sync previews
	argocd app wait previews

clean: ## Clean
	helm uninstall previews
	kind delete cluster

help:
	awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: help clean test sync deploy login status kind e2e all

-include include.mk
