#!/usr/bin/env bash
# Deletes everything created by this project to stop AWS charges.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-wanderlust}"
REGION="${REGION:-ap-south-1}"

read -r -p "Delete cluster '$CLUSTER_NAME' in $REGION and everything in it? [y/N] " ans
[[ "$ans" == "y" ]] || { echo "Aborted."; exit 0; }

echo "==> Removing the ArgoCD application (prunes the app resources)"
kubectl delete -f argocd/application.yaml --ignore-not-found || true

echo "==> Removing monitoring"
helm uninstall stable -n prometheus || true
kubectl delete namespace prometheus --ignore-not-found || true

echo "==> Deleting any remaining LoadBalancer services (they block VPC deletion)"
kubectl get svc -A --no-headers 2>/dev/null | awk '$3=="LoadBalancer"{print $1" "$2}' | \
  while read -r ns name; do kubectl delete svc "$name" -n "$ns"; done || true

echo "==> Deleting the cluster (about 10 minutes)"
eksctl delete cluster --name "$CLUSTER_NAME" --region "$REGION" --wait

echo "Done. Check the EC2, EBS and CloudFormation consoles for leftovers."
