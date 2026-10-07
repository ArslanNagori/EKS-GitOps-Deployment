# Security

## Implemented

| Control | Where |
| --- | --- |
| Dependency and filesystem scanning on every CI run | Trivy, OWASP Dependency-Check |
| Static analysis with a quality gate | SonarQube |
| Credentials kept in Jenkins, referenced by ID | `Jenkinsfile-ci`, `Jenkinsfile-cd` |
| Deployments only through Git | Jenkins commits tags, ArgoCD applies them; no `kubectl` in the pipeline |
| No secrets in the repository | `.gitignore` blocks keys, `.env`, kubeconfig and credential files; screenshots have account IDs and public IPs masked |

## Hardening checklist

Apply these for anything beyond a lab:

- [ ] Use an **IAM role attached to the master EC2 instance** instead of access keys. If the cluster was created by an IAM user, add the role as an EKS access entry first (see [setup-guide.md](setup-guide.md)).
- [ ] Give the role only the permissions it needs (EKS, EC2, IAM pass-role, CloudFormation, VPC) instead of `AdministratorAccess`.
- [ ] Change the initial ArgoCD admin password and delete `argocd-initial-admin-secret`.
- [ ] Change the Grafana admin password after the first login.
- [ ] Limit the node security group to your own IP for the ArgoCD, Prometheus, Grafana and application NodePorts, and close port 22 on the nodes. Prometheus has no login.
- [ ] Prefer `kubectl port-forward` for admin tools, and an Ingress with TLS for the application.
- [ ] Deploy to `https://kubernetes.default.svc` so ArgoCD does not need the `argocd-manager` service account with a long-lived cluster-admin token.
- [ ] Make Trivy and Dependency-Check fail the build above a chosen severity, and scan the built images as well as the filesystem.
- [ ] Use Kubernetes Secrets (or an external secrets tool) for database credentials rather than values in manifests.
- [ ] Rotate any credential that is ever pasted into a chat, ticket or screenshot.

## Reporting

This is a personal learning project. If you spot an issue, please open a GitHub issue.
