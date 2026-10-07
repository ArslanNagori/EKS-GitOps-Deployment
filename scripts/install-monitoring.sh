#!/usr/bin/env bash
# Installs kube-prometheus-stack (Prometheus, Alertmanager, Grafana) as release "stable".
set -euo pipefail

RELEASE="${RELEASE:-stable}"
NAMESPACE="${NAMESPACE:-prometheus}"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install "$RELEASE" prometheus-community/kube-prometheus-stack -n "$NAMESPACE"

echo "==> Waiting for the Grafana deployment"
kubectl rollout status deployment/"${RELEASE}-grafana" -n "$NAMESPACE" --timeout=300s

echo "==> Exposing Prometheus and Grafana as NodePort"
kubectl patch svc "${RELEASE}-kube-prometheus-sta-prometheus" -n "$NAMESPACE" -p '{"spec": {"type": "NodePort"}}'
kubectl patch svc "${RELEASE}-grafana" -n "$NAMESPACE" -p '{"spec": {"type": "NodePort"}}'

kubectl get pods -n "$NAMESPACE"
kubectl get svc -n "$NAMESPACE"

cat <<MSG

Grafana admin password:
  kubectl get secret -n $NAMESPACE ${RELEASE}-grafana -o jsonpath="{.data.admin-password}" | base64 --decode; echo
Change it after the first login, and allow the NodePorts from your own IP only.
MSG
