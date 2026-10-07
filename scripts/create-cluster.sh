#!/usr/bin/env bash
# Creates the EKS cluster (control plane), enables OIDC and adds a 2-node managed node group.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-wanderlust}"
REGION="${REGION:-ap-south-1}"
K8S_VERSION="${K8S_VERSION:-1.36}"
NODE_TYPE="${NODE_TYPE:-c7i-flex.large}"
NODES="${NODES:-2}"
NODE_VOLUME_GB="${NODE_VOLUME_GB:-29}"
KEY_PAIR="${KEY_PAIR:?Set KEY_PAIR to the name of an existing EC2 key pair, e.g. KEY_PAIR=eks-nodegroup-key}"

echo "==> Checking AWS identity"
aws sts get-caller-identity --query Arn --output text

echo "==> 1/3 Creating control plane (about 11 minutes)"
eksctl create cluster \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --version "$K8S_VERSION" \
  --without-nodegroup

echo "==> 2/3 Associating IAM OIDC provider"
eksctl utils associate-iam-oidc-provider \
  --region "$REGION" \
  --cluster "$CLUSTER_NAME" \
  --approve

echo "==> 3/3 Creating managed node group (about 3 minutes)"
eksctl create nodegroup \
  --cluster "$CLUSTER_NAME" \
  --region "$REGION" \
  --name "$CLUSTER_NAME" \
  --node-type "$NODE_TYPE" \
  --nodes "$NODES" --nodes-min "$NODES" --nodes-max "$NODES" \
  --node-volume-size "$NODE_VOLUME_GB" \
  --ssh-access \
  --ssh-public-key "$KEY_PAIR"

echo "==> Nodes"
kubectl get nodes
