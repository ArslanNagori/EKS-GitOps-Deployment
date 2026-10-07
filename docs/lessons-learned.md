# Lessons learned

**Apply large manifests server-side.** The ArgoCD install failed on the ApplicationSet CRD because client-side `kubectl apply` stores the whole object in an annotation. `--server-side --force-conflicts` fixes it, and I now use it in the install script.

**Decide how ArgoCD reaches the cluster before registering anything.** I registered the EKS cluster with `argocd cluster add`, which created a service account with cluster-admin rights and a long-lived token. Because ArgoCD runs in the same cluster, `https://kubernetes.default.svc` would have worked without that token. The application still works, and moving to in-cluster is on the roadmap.

**Read dashboards critically.** Grafana showed 32 in the pod chart and 26 in the pod tile. Both were right: one counts containers and the other pods. Checking with `kubectl get pods -A` took a minute and avoided a wrong claim.

**Right-size from data.** With everything running, the cluster used about 3.7% CPU and 43% memory, and the application itself under 0.5% of CPU. Two 4 GB nodes were enough, so there was no reason to pay for larger ones.

**Keep build and deploy separate.** Having Jenkins commit image tags and ArgoCD apply them made every release a Git commit that could be reviewed and reverted, and it removed cluster credentials from the pipeline.

**Mind the paste.** Pasting several commands together with an interactive one (`aws configure`) fed installer output into the prompts and saved a broken region. Interactive commands are run alone.

**Scans need teeth.** The scans found 69 HIGH/CRITICAL (Trivy) and 109 (Dependency-Check) findings, but the pipeline still passed. Reporting is a start; enforcing thresholds is the next step.

**Tests matter.** SonarQube reports 0% coverage because the app has no unit tests. That is visible, accurate and a clear next improvement.

**Delete what you create.** EKS bills by the hour, so a cleanup script is part of the project, not an afterthought.
