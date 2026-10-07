# Monitoring

Monitoring uses the `kube-prometheus-stack` Helm chart, installed as release `stable` in the `prometheus` namespace.

## Components

| Pod | Purpose |
| --- | --- |
| prometheus-stable-kube-prometheus-sta-prometheus-0 | Metrics storage and queries |
| alertmanager-stable-kube-prometheus-sta-alertmanager-0 | Alert routing |
| stable-grafana | Dashboards |
| stable-kube-prometheus-sta-operator | Manages Prometheus and Alertmanager |
| stable-kube-state-metrics | Kubernetes object metrics (pod phase, deployments) |
| stable-prometheus-node-exporter (one per node) | Node CPU, memory, disk and network |

## Access

Prometheus and Grafana are exposed as NodePort services:

```bash
kubectl get svc -n prometheus
```

Open `http://<NODE_PUBLIC_IP>:<NODEPORT>` from an IP allowed in the node security group. Without opening any ports:

```bash
kubectl port-forward -n prometheus svc/stable-grafana 3000:80
kubectl port-forward -n prometheus svc/stable-kube-prometheus-sta-prometheus 9090:9090
```

Get the Grafana admin password and change it after the first login:

```bash
kubectl get secret -n prometheus stable-grafana -o jsonpath="{.data.admin-password}" | base64 --decode; echo
```

## Dashboards worth showing

- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace (Pods), with namespace `wanderlust`
- Node Exporter / Nodes, for the 2 worker nodes

## Useful queries

```promql
# CPU per pod in the application namespace
sum(rate(container_cpu_usage_seconds_total{namespace="wanderlust"}[5m])) by (pod)

# Memory per pod
sum(container_memory_working_set_bytes{namespace="wanderlust"}) by (pod)

# Pods that are not running
kube_pod_status_phase{namespace="wanderlust", phase!="Running"} == 1
```

## Alerting

Alertmanager is installed with the chart. To send alerts by email, add an SMTP receiver to its configuration with an app password stored in a Kubernetes secret, never in this repo.
