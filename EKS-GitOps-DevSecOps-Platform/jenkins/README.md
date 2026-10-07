# Jenkins jobs

Copies of the Jenkinsfiles from the earlier showcase repo, [DevSecOps-CI-CD-Pipeline](https://github.com/ArslanNagori/DevSecOps-CI-CD-Pipeline). They use the `Shared` Jenkins library ([Shared-Library-Jenkins](https://github.com/ArslanNagori/Shared-Library-Jenkins)).

| File | What it does here |
| --- | --- |
| `Jenkinsfile-ci` | Validates the image tags, checks out the code, runs Trivy, OWASP Dependency-Check and SonarQube (with quality gate), builds the frontend and backend images and pushes them to Docker Hub, then triggers the CD job |
| `Jenkinsfile-cd` | Updates the image tags in `kubernetes/backend.yaml` and `kubernetes/frontend.yaml` with `sed`, commits and pushes to GitHub, and sends an email. ArgoCD then deploys the change to EKS |

Credentials are referenced by Jenkins credential ID only; no secret values are stored in these files.
