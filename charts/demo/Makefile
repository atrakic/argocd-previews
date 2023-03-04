
APP := $(notdir $(CURDIR))
VALUES ?= values.yaml

all: lint
	helm template -f $(VALUES) --set ingress.hosts[0].host="foo.bar" .

lint:
	helm lint .

deploy install:
	helm upgrade --install $(APP) -f $(VALUES) .

clean uninstall:
	helm uninstall $(APP)

list:
	helm list -A --all
