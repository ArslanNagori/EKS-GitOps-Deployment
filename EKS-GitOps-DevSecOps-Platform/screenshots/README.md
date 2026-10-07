# Screenshots

21 screenshots taken during the build, saved as `<name>.png`. Account IDs, public IPs and the cluster endpoint are masked.

## Cluster and application

| File | What it shows |
| --- | --- |
| `eks-cluster-overview.png` | EKS console: cluster `wanderlust` Active, Kubernetes 1.36, Mumbai region |
| `eks-worker-nodes.png` | `kubectl get nodes -o wide`: 2 Ready nodes, Amazon Linux 2023, containerd |
| `wanderlust-kubernetes-workloads.png` | `kubectl get all -n wanderlust`: pods, services, deployments and the ReplicaSet rollout history |
| `wanderlust-pods.png` | `kubectl get pods -o wide`: frontend and backend on one node, MongoDB and Redis on the other |
| `wanderlust-live-application.png` | The Wanderlust app served from the cluster through a NodePort |

## GitOps (ArgoCD)

| File | What it shows |
| --- | --- |
| `argocd-application-synced-healthy.png` | Healthy and Synced to `main`, auto sync on, last sync authored by Jenkins, resource tree of the 4 services and pods |
| `argocd-application-details.png` | Git source (repo, `main`, `kubernetes` path), target namespace, sync options and deployed image tags |

## CI/CD (Jenkins)

| File | What it shows |
| --- | --- |
| `jenkins-ci-stage-view.png` | CI stage view, builds #6 to #10 |
| `jenkins-build-history.png` | Five successful builds in a row |
| `dockerhub-images.png` | Frontend and backend images pushed to Docker Hub |
| `jenkins-cd-commit.png` | The commit Jenkins makes to the Wanderlust repo |
| `jenkins-cd-manifest-diff.png` | The image-tag change in `backend.yaml` and `frontend.yaml` |
| `jenkins-shared-library-config.png` | The `Shared` global pipeline library and its GitHub repository |

## DevSecOps checks

| File | What it shows |
| --- | --- |
| `sonarqube-dashboard.png` | Quality gate Passed; 0 bugs, 1 vulnerability, 0 hotspots, 0% coverage |
| `dependency-check-report.png` | Jenkins Dependency-Check results: 2 critical, 48 high, 52 medium, 7 low |
| `trivy-fs-report.png` | Trivy filesystem scan: 34 + 32 + 3 = 69 HIGH/CRITICAL npm findings |

## Monitoring

| File | What it shows |
| --- | --- |
| `prometheus-wanderlust-cpu-usage.png` | PromQL: CPU of the `wanderlust` namespace as a percentage of cluster CPU |
| `prometheus-network-receive-by-pod.png` | PromQL: network receive rate per pod |
| `prometheus-network-transmit-by-pod.png` | PromQL: network transmit rate per pod |
| `grafana-cluster-overview.png` | Grafana Kubernetes dashboard: 2 nodes, 26 running pods, cluster CPU and memory |
| `grafana-namespace-cpu-memory.png` | Grafana CPU and memory by namespace (argocd, kube-system, prometheus, wanderlust) |
