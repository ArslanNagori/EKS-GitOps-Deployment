# DevSecOps pipeline

Two Jenkins pipelines run on the master EC2 instance. Both load the `Shared` pipeline library ([Shared-Library-Jenkins](https://github.com/ArslanNagori/Shared-Library-Jenkins)), so each stage is a one-line call. The Jenkinsfiles are in [`jenkins/`](../jenkins).

## CI pipeline (`Jenkinsfile-ci`)

Run with two parameters, `FRONTEND_DOCKER_TAG` and `BACKEND_DOCKER_TAG`.

| Stage | Purpose | Average time |
| --- | --- | --- |
| Validate Parameters | Fail fast if a tag is missing | 109 ms |
| Workspace cleanup | Start from a clean workspace | 180 ms |
| Git: Code Checkout | Pull the application code | 1 s |
| Trivy: Filesystem scan | HIGH/CRITICAL findings in dependencies and lock files | 741 ms |
| OWASP: Dependency check | Software composition analysis | 8 s (warm database) |
| SonarQube: Code Analysis | Static analysis | 19 s |
| SonarQube: Quality Gates | Pass or fail the quality gate | 334 ms |
| Exporting environment variables | Backend and frontend env setup | about 1.2 s in total |
| Docker: Build Images | Build frontend and backend images | 1 s (cached layers) |
| Docker: Push to DockerHub | Push both images with the given tags | 11 s |

Average full run: about 51 seconds (builds #6 to #10, all green, see `screenshots/jenkins-ci-stage-view.png`).

Post actions:

- **Always:** archive the Dependency-Check XML and the Trivy report as build artifacts.
- **On success:** trigger the `Wanderlust-CD` job with the same two tags (`wait: false`).

## CD pipeline (`Jenkinsfile-cd`)

| Stage | Purpose |
| --- | --- |
| Workspace cleanup, Git checkout | Fresh checkout of the Wanderlust repo |
| Verify: Docker Image Tags | Print the tags received from CI |
| Update: Kubernetes manifests | `sed` replaces the `image:` tags in `kubernetes/backend.yaml` and `kubernetes/frontend.yaml` |
| Git: Code update and push to GitHub | Commit and push to `main` using the `GitHub-Credential` credential |
| Post | Email notification with the build log attached |

The CD job never talks to the cluster. The push to `main` is the deployment trigger, and ArgoCD does the rest.

## Scan results on this project

| Tool | Result |
| --- | --- |
| Trivy | 69 HIGH/CRITICAL findings: 34 backend, 32 frontend, 3 root lock files |
| OWASP Dependency-Check | 109 findings: 2 critical, 48 high, 52 medium, 7 low |
| SonarQube | Gate passed. 0 bugs, 1 vulnerability (security rating B), 0 hotspots, 2 code smells, 6.1% duplication, 0% coverage |

The tools run in report mode: they publish findings but do not yet fail the build. Making them enforcing is the first item on the roadmap.

## Notes

- The first Dependency-Check run downloads the full vulnerability database and is slow. Keep its data directory persistent so later runs take seconds.
- SonarQube runs as a container on the master machine and its token is stored as a Jenkins credential.
- Credentials are referenced by credential ID only. No secret values are stored in the Jenkinsfiles.
