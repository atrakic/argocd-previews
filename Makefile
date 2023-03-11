#MAKEFLAGS += --silent

SHELL := /bin/bash

.DEFAULT_GOAL := help

SERVER := 127.0.0.1:8080

# Follows naming convention from ./argocd/project.yaml
E2E_CHART ?= demo
DEMO_PR ?= pr-0000-$(E2E_CHART)

all: kind setup port_forward login deploy e2e status ## Do all

kind:
	kind create cluster --config config/kind.yaml --wait 60s || true
	kind version

setup: ## Setup kinD with ArgoCD + Nginx Ingress
	echo ":: $@ :: "
	kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s
	kubectl cluster-info
	scripts/argocd/up.sh
	scripts/ingress/up.sh

status: ## Status
	echo ":: $@ :: "
	argocd version
	argocd --server $(SERVER) --insecure app list
	argocd --server $(SERVER) --insecure proj list
	argocd --server $(SERVER) --insecure app manifests $(DEMO_PR)

port_forward: ## ArgoCD Port forward
	echo ":: $@ :: "
	scripts/argocd/port_forward.sh &
	sleep 1
	curl -o /dev/null -iskL --retry 3 --max-time 3 $(SERVER)

login: ## ArgoCD Login
	echo ":: $@ :: "
	scripts/argocd/login.sh

deploy: ## Deploy a local helm chart with ArgoCD Application previews
	echo ":: $@ :: "
	kubectl apply -f argocd

sync: ## Sync previews
	echo ":: $@ :: "
	argocd --server $(SERVER) --insecure app sync previews
	argocd --server $(SERVER) --insecure app wait previews
	argocd --server $(SERVER) --insecure app sync $(DEMO_PR)
	argocd --server $(SERVER) --insecure app wait $(DEMO_PR)

#HOST="$(DEMO_PR).$(shell curl -sSL ifconfig.co).nip.io"
HOST="$(DEMO_PR).127.0.0.1.nip.io"
e2e: kind setup port_forward login deploy ## E2e local helm chart
	echo ":: $@ :: "
	if [[ -z "$(IMAGE_TAG)" ]]; then echo "Error: need IMAGE_TAG variable"; fi
	helm upgrade --install \
		--create-namespace \
		--namespace=$(DEMO_PR) \
		$(E2E_CHART) ./charts/$(E2E_CHART) \
		--set "image.tag=$(IMAGE_TAG)" \
		--set "image.pullPolicy=Always"; \
	kubectl wait --for=condition=Ready pods --all -n $(DEMO_PR) --timeout=300s; \
	HOST="$(HOST)" tests/e2e.sh; \
	helm -n $(DEMO_PR) get values $(E2E_CHART); \
	helm -n $(DEMO_PR) delete $(E2E_CHART); \
	\
	REPO="atrakic/argocd-previews" \
	CHART_PATH="charts/$(E2E_CHART)" \
	HOST="$(HOST)" \
	APP_ID="$(DEMO_PR)" scripts/create.sh; \
	\
	if [[ -z "$(GITHUB_TOKEN)" ]]; then echo "Error: need GITHUB_TOKEN variable"; fi; \
	\
	if [[ -n "$$(git status -s)" ]]; then \
		echo "Updating chart"; \
		git add charts/previews; \
		git diff --name-only; \
		git commit -m "e2e: $(shell git rev-parse --short HEAD)"; \
		git push -u origin; \
		$(MAKE) sync; \
		kubectl get pod -n $(DEMO_PR) -l "app.kubernetes.io/name=$(E2E_CHART)" -o=custom-columns='DATA:spec.containers[*].image'; \
	fi; \
	\
	HOST="$(HOST)" tests/e2e.sh

# Example how to source remote chart via GH actions.
e2e-remote-chart: ## E2e remote helm chart
	echo ":: $@ :: "
	if [[ -z "$(GITHUB_TOKEN)" ]]; then echo "Error: need GITHUB_TOKEN variable"; fi
	REPO="atrakic/go-static-site" \
	IMAGE_TAG="v0.0.2" \
	CHART_PATH="charts/go-static-site" \
	HOST="go-static-site.127.0.0.1.nip.io" \
	APP_ID="pr-e2e" tests/trigger_create_pr.sh

clean: ## Clean
	kind delete cluster

help:
	awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: help clean test sync deploy login status kind e2e all

-include include.mk
