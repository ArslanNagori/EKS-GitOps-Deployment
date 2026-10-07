# Troubleshooting

Problems hit while building this, with causes and fixes.

## `aws s3 ls` fails with "Provided region_name ... doesn't match a supported format"

**Cause:** several commands were pasted together with `aws configure`. The leftover lines of the paste were typed into the interactive prompts, so the region was saved as a line of installer output.
**Fix:** run `aws configure` alone, one prompt at a time, or write `~/.aws/config` directly with `region = ap-south-1`. With an IAM role on the instance, no `aws configure` is needed at all.

## `eksctl: command not found`

**Cause:** eksctl was not installed on the master machine yet.
**Fix:** download the release tarball for your architecture and install the binary into `/usr/local/bin` (see `scripts/install-tools.sh`).

## ArgoCD install: `applicationsets.argoproj.io is invalid: metadata.annotations: Too long`

**Cause:** a plain `kubectl apply` stores the whole object in an annotation, and this CRD is larger than the 262144-byte limit. The ApplicationSet CRD was therefore not created, and `argocd-applicationset-controller` restarted repeatedly.
**Fix:** apply with server-side apply:

```bash
kubectl apply --server-side --force-conflicts -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## `argocd login` fails with a certificate error

**Cause:** the ArgoCD server uses a self-signed certificate without an IP SAN, so it cannot be verified when you connect by IP.
**Fix:** answer `y` to the prompt or pass `--insecure`.

## `argocd login`: Invalid username or password

**Cause:** the initial password was mistyped.
**Fix:** read it again from the secret with `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`, log in, then change it and delete the secret.

## Registering the cluster adds a powerful service account

**Cause:** `argocd cluster add` registered the EKS cluster through its public endpoint and created an `argocd-manager` service account in `kube-system` with cluster-admin rights and a long-lived token. Because ArgoCD runs inside the same cluster, this extra step is not strictly required.
**Fix / improvement:** deploy to `https://kubernetes.default.svc` (`in-cluster`) instead. Change the application destination, then remove the extra cluster with `argocd cluster rm <url>` and delete the `argocd-manager` service account, cluster role, binding and token secret.

## Prometheus pods show 1/2 or 2/3 right after install

**Cause:** the containers were still starting.
**Fix:** wait a minute and run `kubectl get pods -n prometheus` again.

## `kubectl config get context`: unknown command

**Cause:** wrong subcommand.
**Fix:** the command is `kubectl config get-contexts`.

## `kubectl` returns Unauthorized after switching to an IAM role

**Cause:** the IAM identity that creates an EKS cluster is its only initial admin.
**Fix:** create an access entry for the role (see step 1 of the [setup guide](setup-guide.md)).

## Pods stay Pending

**Cause:** not enough memory or pod slots on the nodes, or a PersistentVolumeClaim with no storage driver.
**Fix:** check `kubectl describe pod <name>` for the scheduling reason. For PVC problems install the EBS CSI driver add-on.

## Cluster deletion hangs

**Cause:** a LoadBalancer service still owns an AWS load balancer inside the VPC.
**Fix:** delete those services before `eksctl delete cluster`.
