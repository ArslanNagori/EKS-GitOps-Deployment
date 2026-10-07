# Reports

| File | What it is |
| --- | --- |
| `trivy-fs-report.txt` | Trivy filesystem scan (HIGH and CRITICAL) from the Jenkins CI job: 34 findings in `backend/package-lock.json`, 32 in `frontend/package-lock.json`, 3 in the root `package-lock.json` |

The OWASP Dependency-Check XML report is archived by the CI job as a build artifact (see `Jenkinsfile-ci`) and is not stored here because of its size.
