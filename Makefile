MAKEFLAGS += --silent

SERVER ?= 127.0.0.1:8080
DEMO_PR ?= demo-pr-0000

.DEFAULT_GOAL := help

all: kind setup port_forward deploy e2e status ## Do all

kind:
	kind create cluster --config tests/kind.yaml --wait 60s || true
	kind version

setup: ## Setup kinD with ArgoCD + Nginx Ingress
	kubectl wait --for=condition=Ready pods --all --all-namespaces --timeout=300s
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

deploy: ## Deploy ArgoCD Application previews from local helm chart
	kubectl apply -f argocd
	helm upgrade --install previews ./charts/previews --set "foo.bar=True"
	argocd app sync $(DEMO_PR)


e2e: ## E2e test (requires GITHUB_TOKEN env)
	echo ":: $@ :: "
	REPO="atrakic/argocd-previews" \
		IMAGE_TAG="stable-alpine" \
		CHART_PATH="charts/demo" \
    HOST="$(DEMO_PR).127.0.0.1.nip.io" \
		APP_ID="$(DEMO_PR)" tests/create.sh \
	\
	if [ -n "$(git status --porcelain)" ]; then
		git status --porcelain
		git add charts/previews
		git diff --name-only
		git commit --allow-empty -m "$@: $(shell git rev-parse --short HEAD)"
		git push -u origin
		HOST=$(DEMO_PR).127.0.0.1.nip.io tests/e2e.sh
	fi

clean: ## Clean
	helm uninstall previews
	kind delete cluster

help:
	awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: help clean test sync deploy login status kind e2e all

-include include.mk
