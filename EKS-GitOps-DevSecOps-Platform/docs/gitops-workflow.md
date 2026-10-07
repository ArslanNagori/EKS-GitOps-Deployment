# GitOps workflow

## The ArgoCD application

`argocd/application.yaml` defines one Application:

- **Source:** the `kubernetes/` folder of the Wanderlust repo
- **Destination:** the EKS cluster registered in ArgoCD as `wanderlust-eks-cluster`, namespace `wanderlust` (created automatically with `CreateNamespace=true`)
- **Sync policy:** automated (auto sync enabled). `prune` (delete resources removed from Git) and `selfHeal` (undo manual changes in the cluster) can be added under `syncPolicy.automated`

## End-to-end flow

1. Push a code change to the application repo.
2. Jenkins CI scans, builds and pushes `backend:<tag>` and `frontend:<tag>` to Docker Hub.
3. Jenkins CD edits the `image:` lines in `kubernetes/backend.yaml` and `kubernetes/frontend.yaml` and commits.
4. ArgoCD polls the repo (about every 3 minutes by default) or receives a refresh, and detects the new revision.
5. ArgoCD applies the change and the Deployments roll out new pods.

## Demo script (for the screen recording)

1. Show `kubectl get pods -n wanderlust` and the app in the browser.
2. Make a visible change in the frontend (for example a heading) and push it.
3. Run the Jenkins CI job; show the stages and the CD job it triggers.
4. Show the new commit in GitHub (changed image tags).
5. Show ArgoCD syncing and the new pods rolling out.
6. Refresh the browser and show the change.
7. Open Grafana and show pod CPU and memory for the `wanderlust` namespace.

## Self-heal demo (only if `selfHeal: true` is enabled)

```bash
kubectl scale deployment backend -n wanderlust --replicas=0
```

ArgoCD reports the app as OutOfSync and, with `selfHeal` on, restores the replica count from Git within a short time. Use your actual deployment name from `kubectl get deploy -n wanderlust`.

## Rollback

Rollback is a Git operation:

```bash
git revert <commit-with-bad-tag>
git push
```

ArgoCD syncs the reverted manifests and the previous image returns.

## Avoiding a build loop

If the CD job pushes to the same repo that triggers the CI job, every deploy would start a new build. Use a commit message prefix that CI ignores (for example `[skip ci]`), or a separate manifests repo or path that the CI trigger does not watch.
