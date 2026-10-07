#!/usr/bin/env bash
# Installs the CLI tools used on the master machine (Ubuntu, x86_64).
set -euo pipefail

echo "==> AWS CLI"
if ! command -v aws >/dev/null; then
  curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q -o /tmp/awscliv2.zip -d /tmp
  sudo /tmp/aws/install
else
  echo "aws already installed (use: sudo /tmp/aws/install --update to upgrade)"
fi

echo "==> kubectl"
if ! command -v kubectl >/dev/null; then
  KVER="$(curl -sL https://dl.k8s.io/release/stable.txt)"
  curl -sSLo /tmp/kubectl "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl"
  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
fi

echo "==> eksctl"
if ! command -v eksctl >/dev/null; then
  ARCH="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')"
  PLATFORM="$(uname -s)_${ARCH}"
  curl -sSLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz"
  tar -xzf "eksctl_${PLATFORM}.tar.gz" -C /tmp && rm "eksctl_${PLATFORM}.tar.gz"
  sudo install -m 0755 /tmp/eksctl /usr/local/bin/eksctl
fi

echo "==> Helm"
if ! command -v helm >/dev/null; then
  curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 /tmp/get_helm.sh && /tmp/get_helm.sh
fi

echo "==> argocd CLI"
if ! command -v argocd >/dev/null; then
  sudo curl -sSL -o /usr/local/bin/argocd \
    https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  sudo chmod +x /usr/local/bin/argocd
fi

echo "==> Versions"
aws --version
kubectl version --client
eksctl version
helm version --short
argocd version --client --short
