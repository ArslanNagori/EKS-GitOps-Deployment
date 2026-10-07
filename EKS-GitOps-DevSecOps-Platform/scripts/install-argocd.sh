#!/usr/bin/env bash
# Installs ArgoCD in the cluster and exposes the server as a NodePort.
set -euo pipefail

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Server-side apply is required: the ApplicationSet CRD is too large for client-side apply.
kubectl apply --server-side --force-conflicts -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

kubectl get pods -n argocd
kubectl get svc argocd-server -n argocd

cat <<'MSG'

Next steps:
  1. Get the initial admin password:
       kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
  2. Log in:   argocd login <NODE_PUBLIC_IP>:<NODEPORT> --username admin --insecure
  3. Change it: argocd account update-password
  4. Delete the initial secret: kubectl -n argocd delete secret argocd-initial-admin-secret
  5. Allow the NodePort in the node security group from your own IP only.
MSG
