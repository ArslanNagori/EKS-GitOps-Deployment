# Architecture

<img src="assets/architecture.svg" alt="Architecture diagram" width="100%">

## Layers

| Layer | What it is | Who manages it |
| --- | --- | --- |
| Master machine | One EC2 instance (Ubuntu) running Jenkins and the DevSecOps tools. All `eksctl`, `kubectl`, `helm` and `argocd` commands are run from here. | Me |
| EKS control plane | Kubernetes API server, etcd, scheduler and controller manager | AWS (managed) |
| Worker nodes | 2 x `c7i-flex.large` EC2 instances in a managed node group | AWS lifecycle, my workloads |
| GitOps | ArgoCD, running in the `argocd` namespace of the cluster | Me |
| Monitoring | Prometheus, Alertmanager and Grafana, in the `prometheus` namespace | Me |

## What runs where

**Master EC2 instance**
- Jenkins (CI and CD jobs)
- Docker engine (image builds)
- SonarQube (container), Trivy, OWASP Dependency-Check
- AWS CLI, eksctl, kubectl, Helm, argocd CLI

Nothing of the application runs here. This machine builds, scans, pushes and manages.

**EKS worker nodes (by namespace)**

| Namespace | Pods |
| --- | --- |
| `kube-system` | aws-node (VPC CNI), kube-proxy, CoreDNS, metrics-server |
| `argocd` | application-controller, applicationset-controller, dex-server, notifications-controller, redis, repo-server, server |
| `wanderlust` | frontend (React), backend (Node.js), MongoDB, Redis |
| `prometheus` | Prometheus, Alertmanager, Grafana, operator, kube-state-metrics, node-exporter (one per node) |

**External services**: GitHub (application code and manifests), Docker Hub (images), email (build notifications).

## Design decisions

- **ArgoCD runs inside the cluster.** It needs to watch live cluster state, and it pulls from Git instead of being pushed to. If the master machine is stopped, ArgoCD keeps the application in sync; only builds stop.
- **Jenkins does not deploy.** The CD job only edits image tags in Git. The cluster is changed only by ArgoCD, so Git is the single source of truth and every change is a commit that can be reverted.
- **Managed node group.** AWS handles node provisioning and replacement, which keeps the setup short and reproducible with one `eksctl` command.
- **OIDC provider enabled.** This allows IAM roles for service accounts later (for example for the EBS CSI driver or the AWS Load Balancer Controller).
- **NodePort instead of LoadBalancer for tools.** ArgoCD, Prometheus and Grafana use NodePort, with security-group rules limited to my IP. This avoids paying for extra load balancers during a learning project.
- **Namespaces per concern.** `argocd`, `wanderlust` and `prometheus` keep resources separate and easy to delete.

## Request and deployment flow

```
Developer -> GitHub -> Jenkins CI (scan, build, push) -> Docker Hub
                                   |
                                   v
                          Jenkins CD (update tag) -> GitHub manifests
                                                          |
                                           ArgoCD (in EKS) pulls and syncs
                                                          |
                                                          v
                                            Wanderlust pods on the nodes
                                                          ^
                                    Prometheus scrapes -> Grafana dashboards
```
