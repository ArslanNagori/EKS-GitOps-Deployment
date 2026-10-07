# Cost and cleanup

Prices change, so check the current AWS pricing pages for your region. These are the things that bill:

| Item | Billed |
| --- | --- |
| EKS control plane | Per hour while the cluster exists, even when idle |
| Worker nodes (2 x `c7i-flex.large`) | Per hour while running |
| Master EC2 instance (Jenkins) | Per hour while running |
| EBS volumes (nodes, master, PVCs) | Per GB-month until deleted |
| Public IPv4 addresses | Per hour per address |
| Load balancers (if you add LoadBalancer services) | Per hour plus data |
| Data transfer | Per GB out |

## Keeping costs down

- Treat the cluster as temporary: create it for a session and delete it afterwards.
- Stop the master instance when you are not using it. Jenkins keeps its data on the volume.
- This project uses NodePort instead of LoadBalancer services to avoid load balancer charges.
- Set an AWS Budget alert so a forgotten cluster does not surprise you.

## Tear down

```bash
make destroy        # or ./scripts/cleanup.sh
```

The script removes the ArgoCD application, uninstalls the monitoring release, deletes any remaining LoadBalancer services (they block VPC deletion) and runs `eksctl delete cluster`.

Afterwards check these consoles for leftovers: EC2 (instances, volumes, Elastic IPs, load balancers), CloudFormation (stacks named `eksctl-wanderlust-*`) and EKS.
