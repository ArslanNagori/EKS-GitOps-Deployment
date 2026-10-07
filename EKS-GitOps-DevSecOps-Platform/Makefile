# One-command entry points for the EKS GitOps platform.
# Usage: make help

CLUSTER_NAME ?= wanderlust
REGION       ?= ap-south-1

.DEFAULT_GOAL := help
.PHONY: help tools cluster argocd register app monitoring status destroy

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

tools: ## Install AWS CLI, kubectl, eksctl, Helm and the argocd CLI
	./scripts/install-tools.sh

cluster: ## Create the EKS cluster and the 2-node managed node group (needs KEY_PAIR)
	CLUSTER_NAME=$(CLUSTER_NAME) REGION=$(REGION) ./scripts/create-cluster.sh

argocd: ## Install ArgoCD and expose it as a NodePort
	./scripts/install-argocd.sh

register: ## Register this EKS cluster with ArgoCD (run after argocd login)
	argocd cluster add "$$(kubectl config current-context)" --name wanderlust-eks-cluster --yes

app: ## Create the ArgoCD Application for Wanderlust
	kubectl apply -f argocd/application.yaml

monitoring: ## Install Prometheus, Alertmanager and Grafana
	./scripts/install-monitoring.sh

status: ## Show nodes and pods
	kubectl get nodes -o wide
	kubectl get pods -A

destroy: ## Delete the cluster and everything in it (stops billing)
	CLUSTER_NAME=$(CLUSTER_NAME) REGION=$(REGION) ./scripts/cleanup.sh
