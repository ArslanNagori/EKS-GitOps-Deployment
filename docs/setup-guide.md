# Setup guide

All commands run on the master EC2 instance unless stated otherwise. Replace values in `<angle brackets>`. Each phase also has a `make` target (see the [README](../README.md#quick-start)): `make tools`, `make cluster`, `make argocd`, `make register`, `make app`, `make monitoring`, `make destroy`.

## 0. Prerequisites

- An AWS account and the Jenkins master instance from the [DevSecOps pipeline repo](https://github.com/ArslanNagori/DevSecOps-CI-CD-Pipeline)
- A key pair for the worker nodes (created in the EC2 console, here called `eks-nodegroup-key`)
- A GitHub repo with the Kubernetes manifests (`kubernetes/` folder in the Wanderlust repo)
- At least 30 GB of disk on the master machine

## 1. Authenticate the AWS CLI

The preferred way on EC2 is an **IAM role attached to the instance**, so there are no access keys to leak. If you use an IAM user instead, run `aws configure` on its own, never pasted together with other commands, and rotate the key afterwards.

```bash
aws sts get-caller-identity
```

If the cluster was created by an IAM user and you later switch to an instance role, add the role to the cluster first:

```bash
aws eks create-access-entry --cluster-name wanderlust --region ap-south-1 \
  --principal-arn arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>
aws eks associate-access-policy --cluster-name wanderlust --region ap-south-1 \
  --principal-arn arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME> \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster
```

## 2. Install the tools

```bash
./scripts/install-tools.sh
aws --version && kubectl version --client && eksctl version && helm version && argocd version --client
```

## 3. Create the EKS cluster

```bash
./scripts/create-cluster.sh
```

The script runs three steps:

1. `eksctl create cluster --without-nodegroup` creates the VPC, subnets and control plane (about 11 minutes), and installs the vpc-cni, kube-proxy, coredns and metrics-server add-ons.
2. `eksctl utils associate-iam-oidc-provider` enables the OIDC provider.
3. `eksctl create nodegroup` adds 2 managed `c7i-flex.large` nodes (about 3 minutes).

Verify:

```bash
kubectl get nodes
```

Both nodes should be `Ready`.

## 4. Install ArgoCD

```bash
./scripts/install-argocd.sh
```

Log in and change the initial password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
argocd login <NODE_PUBLIC_IP>:<ARGOCD_NODEPORT> --username admin --insecure
argocd account update-password
kubectl -n argocd delete secret argocd-initial-admin-secret
```

`--insecure` is needed because ArgoCD uses a self-signed certificate that has no IP SAN.

## 5. Deploy the application through ArgoCD

Register the EKS cluster with ArgoCD (this creates an `argocd-manager` service account in `kube-system` with a long-lived token), then create the application:

```bash
kubectl config get-contexts
argocd cluster add <context-name> --name wanderlust-eks-cluster
kubectl apply -f argocd/application.yaml
argocd app get wanderlust
```

The app should become **Synced** and **Healthy**. Note: because ArgoCD runs inside this same cluster, `https://kubernetes.default.svc` also works as the destination and avoids the extra service account and token. That is listed under next steps in the README. Check the pods:

```bash
kubectl get pods,svc -n wanderlust
```

## 6. Connect the Jenkins CD job

The CD job (see [jenkins/README.md](../jenkins/README.md)) updates the image tags in `kubernetes/backend.yaml` and `kubernetes/frontend.yaml`, commits and pushes. ArgoCD picks the commit up through its auto-sync.

## 7. Install monitoring

```bash
./scripts/install-monitoring.sh
kubectl get pods -n prometheus
```

Wait until every pod is fully ready (for example 2/2 and 3/3). See [monitoring.md](monitoring.md) for access and dashboards.

## 8. Restrict access

NodePort services are reachable on the node's public IP wherever the node security group allows it. Allow the NodePort range used by ArgoCD, Prometheus and Grafana **from your own IP only**, and keep port 22 on the nodes closed or restricted. Prometheus has no login, so it should never be open to the internet. As an alternative, skip the inbound rules and use `kubectl port-forward` from the master.

## 9. Clean up

```bash
./scripts/cleanup.sh
```

Delete LoadBalancer services first (the script does), otherwise the VPC deletion hangs. Afterwards check the EC2, EBS and CloudFormation consoles for leftovers, and stop the master instance if you are not using it.
