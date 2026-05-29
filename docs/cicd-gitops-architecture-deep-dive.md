# MedFlow CI/CD and GitOps Architecture Deep Dive

This document explains the MedFlow delivery architecture from developer commit to production monitoring. It is written for DevOps engineers who need to explain the complete workflow to managers, teammates, auditors, and platform engineers.

MedFlow is a healthcare-style microservices platform. The repository contains application services, Dockerfiles, GitHub Actions pipelines, Helm charts, Argo CD application definitions, Kubernetes security policies, Terraform infrastructure, monitoring manifests, and operational scripts.

The main delivery model used here is:

- Continuous Integration with GitHub Actions.
- DevSecOps scanning inside CI and scheduled security workflows.
- Container image publishing to Amazon ECR.
- Helm-based Kubernetes manifests.
- GitOps deployment with Argo CD.
- Runtime deployment on Amazon EKS.
- Traffic routing through Kubernetes Service, Ingress, Kong, and optional Istio.
- Post-deployment observability with Prometheus, Grafana, Alertmanager, and ELK.

## Executive Summary

In MedFlow, developers do not manually deploy containers to Kubernetes. They push code to GitHub. GitHub Actions validates the code, tests it, scans it, builds a Docker image, pushes that image to Amazon ECR, and updates the Helm values file with the new image tag. That Git commit becomes the desired state. Argo CD watches the Git repository, detects the changed Helm values file, renders the Helm chart, and reconciles the EKS cluster until the live Kubernetes state matches Git.

This is a GitOps operating model. Git is the source of truth, Argo CD is the deployment reconciler, and Kubernetes is the runtime scheduler.

## Current Repository Implementation

Important files:

| Area | Files |
|---|---|
| CI pipeline | `.github/workflows/ci.yml` |
| CD pipeline | `.github/workflows/cd.yml` |
| Security workflow | `.github/workflows/security.yml` |
| Helm chart | `kubernetes/helm-charts/medflow/` |
| Dev values | `kubernetes/helm-charts/medflow/values-dev.yaml` |
| Image tag updater | `scripts/setup/update_helm_image_tag.py` |
| Argo CD application | `kubernetes/argocd/application.yaml` |
| External Secrets Operator | `kubernetes/argocd/external-secrets-application.yaml` |
| External secret sync | `kubernetes/external-secrets/` |
| Kong gateway | `kubernetes/kong/` |
| Istio traffic management | `kubernetes/istio/` |
| Kubernetes security policies | `security/policies/` |
| Prometheus | `monitoring/prometheus/` |
| ELK | `monitoring/elk/` |
| Grafana dashboards | `monitoring/grafana/dashboards/` |
| Terraform dev infrastructure | `infrastructure/environments/dev/` |
| Terraform modules | `infrastructure/modules/` |
| Local development | `docker-compose.yml`, `Makefile` |

Service map:

| User-facing route | Service | Current repo location | Responsibility |
|---|---|---|---|
| `/auth` | `auth-service` | `src/services/auth-service` | Login, JWT issuing, roles, authentication health and metrics. |
| `/patients` | `patient-service` | `src/services/patient-service` | Patient demographics and profile workflows. |
| `/appointments` | `appointment-service` | `src/services/appointment-service` | Appointment scheduling workflows. |
| `/records` | `records-service` | `src/services/records-service` | Medical record metadata and document references. |
| `/pharmacy` | `pharmacy-service` | `src/services/pharmacy-service` | Prescription workflow. |
| `/billing` | `billing-service` | `src/services/billing-service` | Billing, invoices, payments, and claim-like records. |
| `/notifications` | `notification-service` | `src/services/notification-service` | Email/SMS-style notification events. |
| `/` | `frontend` | `src/frontend` | Web interface for patients and staff. |

Current routing note:

The repository currently includes full service folders and Helm values for all services. The sample Kong and Istio manifests route only the auth path today. Extending the gateway layer means adding paths for `/patients`, `/appointments`, `/records`, `/pharmacy`, `/billing`, and `/notifications` to the Ingress, Kong, or Istio VirtualService manifests.

## High-Level Text Diagram

```text
Developer
  |
  | git push / pull request
  v
GitHub Repository
  |
  | triggers
  v
GitHub Actions CI
  |
  | detect changed services
  | test, coverage, dependency scan, image build, image scan
  v
Amazon ECR
  |
  | stores immutable image tags
  v
GitHub Actions updates Helm values-dev.yaml
  |
  | commits new image tag back to Git
  v
Git Repository as Desired State
  |
  | watched by Argo CD
  v
Argo CD Application medflow-dev
  |
  | renders Helm chart and syncs
  v
Amazon EKS / Kubernetes
  |
  | Deployment rolling update
  | Service selects healthy pods
  | Ingress/Kong/Istio route traffic
  v
MedFlow services live
  |
  | metrics, logs, alerts
  v
Prometheus + Grafana + Alertmanager + ELK
```

## End-to-End Workflow

```text
1. Developer writes code.
2. Developer pushes to GitHub.
3. GitHub Actions CI starts.
4. CI detects which services changed.
5. CI installs dependencies.
6. CI runs unit tests and coverage.
7. CI runs dependency and security scans.
8. CI authenticates to AWS using GitHub OIDC.
9. CI builds Docker images with Docker Buildx.
10. CI pushes images to Amazon ECR.
11. CI scans pushed images with Trivy.
12. CI updates Helm values with the image tag.
13. CI commits the Helm values change to Git.
14. Argo CD detects the Git change.
15. Argo CD renders the Helm chart.
16. Argo CD applies desired state to EKS.
17. Kubernetes performs a rolling update.
18. New pods pull images from ECR.
19. Readiness and liveness probes validate pods.
20. Kubernetes Services route traffic to ready pods.
21. Kong or Istio routes external/API traffic.
22. Prometheus scrapes metrics.
23. Filebeat ships logs to ELK.
24. Grafana dashboards and alerts support operations.
```

## Architecture Method and Corporate Terms

| Term | Meaning in MedFlow |
|---|---|
| CI | Continuous Integration. Every code change is tested and scanned before it becomes a deployable artifact. |
| CD | Continuous Delivery. Deployments are automated but can include approvals for staging and production. |
| GitOps | Git stores desired infrastructure/application state; Argo CD reconciles Kubernetes to match Git. |
| DevSecOps | Security checks are embedded into CI/CD instead of happening only after release. |
| IaC | Infrastructure as Code. Terraform defines AWS resources such as VPC, EKS, ECR, RDS, and IAM. |
| Desired state | The intended cluster state stored in Git as Helm values and Kubernetes manifests. |
| Reconciliation | Argo CD compares live cluster state with Git and applies changes to remove drift. |
| Immutable artifact | A Docker image tagged by commit SHA and stored in ECR. |
| Progressive delivery | Releasing traffic gradually using canary or blue-green techniques. |
| Blue-green deployment | Two production versions run side by side; traffic is switched from blue to green. |
| Shift-left security | Running security checks earlier in the development lifecycle. |
| OIDC federation | GitHub Actions receives short-lived AWS credentials without storing static AWS keys. |
| SARIF | Static Analysis Results Interchange Format, used to upload scanner findings to GitHub Security. |
| SBOM | Software Bill of Materials, a machine-readable inventory of dependencies in a build artifact. |
| Golden signals | Latency, traffic, errors, and saturation; core service health indicators. |
| MTTR | Mean Time To Recovery; how quickly the team restores service after failure. |
| Change failure rate | Percentage of deployments that cause incidents, rollback, or hotfixes. |

## How This Was Achieved From Scratch

This is the practical implementation sequence a DevOps engineer would follow to build the current MedFlow platform.

```text
1. Create monorepo structure
   -> src/services/*
   -> src/frontend
   -> kubernetes
   -> infrastructure
   -> monitoring
   -> security
   -> docs

2. Build application service template
   -> FastAPI app
   -> /health endpoint
   -> /metrics endpoint
   -> tests
   -> requirements.txt
   -> Dockerfile

3. Add local development stack
   -> docker-compose.yml with PostgreSQL, Redis, auth-service
   -> Makefile commands for dev, test, lint, validate

4. Add Terraform infrastructure
   -> VPC
   -> ECR repositories
   -> GitHub OIDC IAM role
   -> EKS cluster
   -> RDS PostgreSQL
   -> S3/DynamoDB Terraform backend
   -> External Secrets IRSA role

5. Add Kubernetes packaging
   -> Helm chart
   -> values.yaml base defaults
   -> values-dev.yaml environment values
   -> Deployment, Service, Ingress, HPA, PDB, NetworkPolicy templates
   -> secret references only, no plaintext secret values

6. Add CI pipeline
   -> changed service detection
   -> dependency install
   -> pytest and coverage
   -> Docker Buildx
   -> ECR push
   -> Trivy scan
   -> Helm image tag update

7. Add GitOps CD
   -> Argo CD Application
   -> Git repository path points to Helm chart
   -> automated sync, prune, self-heal
   -> External Secrets Operator installed as a platform add-on

8. Add security automation
   -> OWASP dependency scan
   -> Gitleaks
   -> Checkov
   -> tfsec
   -> Kubescape
   -> Trivy
   -> Syft SBOM

9. Add traffic layer
   -> Kubernetes Ingress
   -> Kong rate limiting
   -> Istio Gateway, VirtualService, DestinationRule
   -> blue-green traffic splitting

10. Add observability
    -> Prometheus scrape config
    -> alert rules
    -> Grafana dashboards
    -> Filebeat, Logstash, Elasticsearch, Kibana

11. Add operations
    -> runbooks
    -> rollback paths
    -> disaster recovery scripts
    -> cost optimization scripts
```

Minimum command flow for a new environment:

```bash
# 1. Validate locally
make validate

# 2. Create or verify Terraform backend first
terraform -chdir=infrastructure/global/s3-backend init
terraform -chdir=infrastructure/global/s3-backend apply

# 3. Provision dev infrastructure
terraform -chdir=infrastructure/environments/dev init
terraform -chdir=infrastructure/environments/dev plan
terraform -chdir=infrastructure/environments/dev apply

# 4. Configure GitHub secrets and environment protection
# Required examples:
# - AWS_ACCOUNT_ID
# - CODECOV_TOKEN
# - ARGOCD_SERVER_DEV
# - ARGOCD_PASSWORD_DEV
# - ARGOCD_SERVER_STAGING
# - ARGOCD_PASSWORD_STAGING
# - SLACK_WEBHOOK_URL

# 5. Install Argo CD in the EKS cluster, then apply app manifests
terraform -chdir=infrastructure/environments/dev output external_secrets_role_arn
# Replace <EXTERNAL_SECRETS_ROLE_ARN> in kubernetes/argocd/external-secrets-application.yaml.
# Add /medflow/dev/app values in AWS Secrets Manager through an approved secure process.
kubectl apply -f kubernetes/argocd/external-secrets-application.yaml
kubectl apply -f security/policies/pod-security-admission.yaml
kubectl apply -f kubernetes/external-secrets/cluster-secret-store.yaml
kubectl apply -f kubernetes/external-secrets/medflow-dev-external-secret.yaml
kubectl apply -f kubernetes/argocd/project.yaml
kubectl apply -f kubernetes/argocd/application.yaml

# 6. Push application change to main
git push origin main

# 7. Watch delivery
argocd app get medflow-dev
kubectl get pods -n medflow-dev
```

## Tool Versions Used or Pinned in This Repository

Versions below are taken from repository files where they are explicitly pinned. GitHub Actions that use `@master`, `@main`, or `latest` are not pinned to a fixed version.

| Tool | Version or Source | Where |
|---|---|---|
| Python runtime | `3.12` in CI, `python:3.12-slim` in Dockerfiles | `.github/workflows/ci.yml`, service Dockerfiles |
| FastAPI | `0.115.6` | service `requirements.txt` |
| Uvicorn | `0.34.0` | service `requirements.txt` |
| SQLAlchemy | `2.0.36` | service `requirements.txt` |
| Psycopg | `3.2.3` | service `requirements.txt` |
| Pydantic | `2.10.4` | service `requirements.txt` |
| pytest | `8.3.4` | service `requirements.txt` |
| Ruff | `0.8.4` | service `requirements.txt` |
| prometheus-client | `0.21.1` | service `requirements.txt` |
| Node.js image | `node:20-alpine` | `src/frontend/Dockerfile` |
| Nginx unprivileged | `1.27-alpine` | `src/frontend/Dockerfile` |
| React | `19.0.0` | `src/frontend/package.json` |
| Vite | `^6.0.7` | `src/frontend/package.json` |
| TypeScript | `^5.7.2` | `src/frontend/package.json` |
| PostgreSQL local image | `postgres:16-alpine` | `docker-compose.yml` |
| Redis local image | `redis:7-alpine` | `docker-compose.yml` |
| Terraform | `>= 1.6.0`, CI setup `~1.6` | Terraform files and security workflow |
| AWS provider | `~> 5.0` | `infrastructure/environments/dev/main.tf` |
| terraform-aws-modules/eks/aws | `~> 20.0` | `infrastructure/modules/eks/main.tf` |
| EKS cluster version | variable-driven | `infrastructure/modules/eks` |
| Helm chart API | `apiVersion: v2` | `kubernetes/helm-charts/medflow/Chart.yaml` |
| MedFlow Helm chart | `0.1.0` | `Chart.yaml` |
| Argo CD CLI | latest download in workflow | `.github/workflows/cd.yml` |
| Elasticsearch | `8.15.3` | `monitoring/elk/elasticsearch.yaml` |
| Logstash | `8.15.3` | `monitoring/elk/logstash.yaml` |
| Filebeat | `8.15.3` | `monitoring/elk/filebeat.yaml` |
| GitHub checkout action | `actions/checkout@v4` | workflows |
| Python setup action | `actions/setup-python@v5` | CI workflow |
| AWS credentials action | `aws-actions/configure-aws-credentials@v4` | CI/CD workflows |
| ECR login action | `aws-actions/amazon-ecr-login@v2` | CI/security workflows |
| Docker Buildx action | `docker/setup-buildx-action@v3` | CI workflow |
| Docker build-push action | `docker/build-push-action@v5` | CI workflow |
| CodeQL SARIF upload | `github/codeql-action/upload-sarif@v3` | CI/security workflows |
| paths-filter | `dorny/paths-filter@v3` | CI workflow |
| upload-artifact | `actions/upload-artifact@v4` | workflows |
| GitHub script | `actions/github-script@v7` | security workflow |
| Slack action | `slackapi/slack-github-action@v1.26.0` | CD workflow |
| tfsec action | `aquasecurity/tfsec-action@v1.0.0` | security workflow |
| Trivy action | `aquasecurity/trivy-action@master` | CI workflow |
| Checkov action | `bridgecrewio/checkov-action@master` | security workflow |
| Kubescape action | `kubescape/github-action@main` | security workflow |
| Gitleaks action | `gitleaks/gitleaks-action@v2` | security workflow |
| Syft SBOM action | `anchore/sbom-action@v0` | security workflow |
| OWASP Dependency Check action | `dependency-check/Dependency-Check_Action@main` | CI workflow |

Recommendation: for production, pin all actions to immutable commit SHAs or stable semver tags instead of `master`, `main`, or `latest`.

## Step-by-Step Explanation

### 1. Developer Writes Code

What happens:

The developer updates a service under `src/services/`, the frontend under `src/frontend/`, infrastructure under `infrastructure/`, Kubernetes manifests under `kubernetes/`, or operational assets under `monitoring/` and `security/`.

Where this is used:

- Backend services: `src/services/auth-service`, `patient-service`, `appointment-service`, `records-service`, `pharmacy-service`, `billing-service`, `notification-service`.
- Frontend: `src/frontend`.
- Local commands: `Makefile`.

Concepts:

- Microservices.
- Service ownership.
- Trunk-based development or branch-based development.
- Local feedback loop.

How we achieved it:

Each backend service follows a similar FastAPI layout with `app/`, `tests/`, `requirements.txt`, and `Dockerfile`. This makes the CI pipeline reusable across services.

Other ways:

- Monorepo with Bazel/Nx/Turborepo for stronger dependency graph handling.
- Polyrepo, one repository per service.
- Git submodules or platform templates for service scaffolding.

### 2. Developer Pushes Code to GitHub

What happens:

The developer pushes to `main`, `develop`, or opens a pull request to `main`.

Where this is configured:

```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
```

File:

- `.github/workflows/ci.yml`.

Concepts:

- Event-driven automation.
- Pull request validation.
- Branch protection.
- Change control.

How we achieved it:

GitHub Actions is configured to automatically start the CI workflow on pushes and pull requests.

Other ways:

- GitLab CI.
- CircleCI.
- Azure DevOps Pipelines.
- Buildkite.

### 3. GitHub Actions CI Starts

What happens:

The CI workflow named `CI - Build, Test & Push to ECR` starts on a GitHub-hosted Ubuntu runner.

Where this is configured:

- `.github/workflows/ci.yml`.

Important settings:

```yaml
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
```

This cancels older workflow runs on the same branch when a newer commit arrives.

Concepts:

- CI runner.
- Job orchestration.
- Concurrency control.
- Pipeline efficiency.

How we achieved it:

The pipeline uses separate jobs for change detection, test/scan, dependency scan, and image build/push.

Other ways:

- Use self-hosted runners for faster builds or private network access.
- Use reusable GitHub workflows.
- Use composite actions for repeated build logic.

### 4. Detect Changed Services

What happens:

The pipeline identifies which services changed and builds a dynamic matrix.

Where this is configured:

```yaml
uses: dorny/paths-filter@v3
```

File:

- `.github/workflows/ci.yml`.

Why this matters:

MedFlow is a monorepo. Without change detection, every commit would test and build every service, even if only one service changed.

Concepts:

- Monorepo change detection.
- Matrix builds.
- Selective CI.
- Build optimization.

How we achieved it:

Each service path is mapped to a filter. If `src/services/auth-service/**` changes, the matrix includes `auth-service`.

Other ways:

- GitHub Actions `paths` filters per workflow.
- Nx affected graph.
- Bazel query.
- Turborepo pipeline graph.
- Manual service list.

### 5. Code Quality Checks

What happens:

The repository includes a `Makefile` target for linting:

```bash
make lint
```

It runs Ruff for the auth service:

```bash
python3 -m ruff check app tests
```

Where this is configured:

- `Makefile`.
- Service dependency files include `ruff==0.8.4`.

Current CI note:

The CI workflow has tests and coverage, and SonarQube is present but commented out. A production-grade CI should add Ruff or equivalent linting directly into `.github/workflows/ci.yml`.

Concepts:

- Static analysis.
- Linting.
- Formatting.
- Code quality gate.

How we achieved it:

Ruff is included in service dependencies and wired into local validation.

Other ways:

- Black for formatting.
- isort for import sorting.
- Flake8/Pylint for Python linting.
- SonarCloud or SonarQube for code smells, bugs, coverage, and maintainability.
- Pre-commit hooks to catch issues before push.

### 6. Test Stage

What happens:

For each changed Python service, CI installs dependencies and runs:

```bash
pytest tests/ -v --cov=app --cov-report=xml --cov-report=term-missing
```

Where this is configured:

- `.github/workflows/ci.yml`.
- Service tests under `src/services/*/tests/`.

Tools:

- `pytest==8.3.4`.
- `pytest-cov` installed during CI.
- Codecov upload through `codecov/codecov-action@v4`.

Concepts:

- Unit testing.
- Integration testing.
- Code coverage.
- Test isolation.
- Quality gate.

How we achieved it:

The pipeline sets test environment variables and uses SQLite for fast CI tests:

```yaml
DATABASE_URL: "sqlite:///./test.db"
SECRET_KEY: "test-secret-key-for-ci"
ENVIRONMENT: "test"
PYTHONPATH: "."
```

Other ways:

- Run tests in Docker Compose with PostgreSQL and Redis.
- Use Testcontainers.
- Use ephemeral Kubernetes namespaces.
- Split unit, integration, contract, and end-to-end test jobs.
- Add coverage threshold enforcement.

### 7. Security Scan Stage

What happens:

MedFlow uses multiple security workflows:

- OWASP Dependency Check in CI.
- Trivy image scanning in CI.
- Checkov and tfsec for Terraform.
- Kubescape for Kubernetes manifests.
- Gitleaks for secrets.
- Syft for SBOM generation.

Where this is configured:

- `.github/workflows/ci.yml`.
- `.github/workflows/security.yml`.
- `security/scanning/checkov-config.yaml`.
- `security/scanning/trivy-config.yaml`.

Concepts:

- DevSecOps.
- Software Composition Analysis.
- Secret scanning.
- Container vulnerability scanning.
- IaC scanning.
- Kubernetes posture scanning.
- SBOM.
- SARIF upload.

How we achieved it:

Security checks run on pull requests, main branch pushes, and a nightly schedule:

```yaml
schedule:
  - cron: "0 2 * * *"
```

Findings are uploaded to GitHub Security when SARIF is produced.

Other ways:

- Snyk.
- GitHub Advanced Security.
- Semgrep.
- Aqua Security.
- Prisma Cloud.
- Wiz.
- Anchore Enterprise.
- Grype instead of or alongside Trivy.
- Kyverno policies in admission control.

### 8. Docker Build Stage

What happens:

CI builds a Docker image for each changed service.

Where this is configured:

- `.github/workflows/ci.yml`.
- Service Dockerfiles under `src/services/*/Dockerfile`.
- Frontend Dockerfile under `src/frontend/Dockerfile`.

Backend Dockerfile pattern:

- Base image: `python:3.12-slim`.
- Creates a non-root `medflow` user.
- Installs dependencies in a virtual environment.
- Exposes port `8000`.
- Runs Uvicorn.
- Defines a container health check.

Frontend Dockerfile pattern:

- Builds with `node:20-alpine`.
- Serves static assets with `nginxinc/nginx-unprivileged:1.27-alpine`.
- Exposes port `8080`.

Concepts:

- Containerization.
- Build context.
- Multi-stage build for frontend.
- Non-root containers.
- OCI image labels.
- Layer caching.

How we achieved it:

The workflow uses Docker Buildx:

```yaml
uses: docker/setup-buildx-action@v3
```

and:

```yaml
uses: docker/build-push-action@v5
```

Image tags use the Git commit SHA:

```text
ECR_REGISTRY/medflow/auth-service:<github.sha>
```

Other ways:

- Kaniko in Kubernetes.
- Buildah/Podman.
- AWS CodeBuild.
- Docker Bake.
- Cloud Native Buildpacks.
- Jib for Java workloads.

### 9. AWS Authentication with OIDC

What happens:

GitHub Actions assumes an AWS IAM role using OpenID Connect.

Where this is configured:

- `.github/workflows/ci.yml`.
- `.github/workflows/cd.yml`.
- `infrastructure/modules/github-oidc/main.tf`.

Concepts:

- Federated identity.
- Short-lived credentials.
- Least privilege IAM.
- No long-lived AWS access keys.

How we achieved it:

Terraform creates:

- `aws_iam_openid_connect_provider.github`.
- `aws_iam_role.github_actions`.
- IAM policy allowing ECR push/pull actions.

GitHub Actions uses:

```yaml
uses: aws-actions/configure-aws-credentials@v4
```

Other ways:

- Static AWS access keys stored in GitHub secrets. Not recommended.
- AWS CodeBuild with service role.
- GitHub self-hosted runners on EC2 with instance profiles.
- HashiCorp Vault dynamic AWS credentials.

### 10. Push Image to Amazon ECR

What happens:

After the image builds, CI pushes it to Amazon ECR.

Where this is configured:

- `.github/workflows/ci.yml`.
- `infrastructure/modules/ecr/main.tf`.

Terraform ECR settings:

- Repository per service: `medflow/<service>`.
- Immutable image tags.
- AES256 encryption.
- Scan on push.
- Lifecycle policy retains the newest images.

Concepts:

- Container registry.
- Immutable tags.
- Artifact repository.
- Image lifecycle management.
- Supply chain traceability.

How we achieved it:

GitHub Actions logs in using:

```yaml
uses: aws-actions/amazon-ecr-login@v2
```

Then `docker/build-push-action` pushes the image.

Other ways:

- Docker Hub.
- GitHub Container Registry.
- Harbor.
- Nexus/Artifactory.
- Google Artifact Registry.
- Azure Container Registry.

### 11. Trivy Image Scan

What happens:

The pushed image is scanned for `HIGH` and `CRITICAL` vulnerabilities.

Where this is configured:

- `.github/workflows/ci.yml`.

Current behavior:

```yaml
exit-code: "0"
```

This uploads findings but does not fail the build.

Concepts:

- Container image vulnerability scanning.
- CVE severity.
- SARIF.
- Security observability.

How we achieved it:

The Trivy action scans the exact image reference that was pushed to ECR and uploads SARIF to GitHub Security.

Other ways:

- Fail builds on critical CVEs.
- Use an allowlist/ignore file for accepted risk.
- Scan both filesystem and images.
- Scan base images before use.
- Use runtime image admission policies.

### 12. Update Helm Values

What happens:

The CI workflow updates the service image tag in the Helm values file.

Where this is configured:

- `.github/workflows/ci.yml`.
- `scripts/setup/update_helm_image_tag.py`.
- `kubernetes/helm-charts/medflow/values-dev.yaml`.

Example:

```yaml
services:
  auth:
    image:
      repository: medflow/auth-service
      tag: 75f9993206005128e2ffaec41951bfbf6aa072aa
```

Concepts:

- GitOps state mutation.
- Environment-specific configuration.
- Helm values.
- Image promotion.

How we achieved it:

The script converts service names such as `auth-service` to Helm keys such as `auth`, then writes the new tag:

```bash
python scripts/setup/update_helm_image_tag.py \
  --service auth-service \
  --tag <github.sha> \
  --values-file kubernetes/helm-charts/medflow/values-dev.yaml
```

Other ways:

- Argo CD Image Updater.
- Flux Image Automation Controller.
- Kustomize image patches.
- Separate GitOps repository.
- Helmfile.
- Environment promotion PRs instead of direct commit.

### 13. Commit Updated Helm Values to Git

What happens:

GitHub Actions commits the changed `values-dev.yaml` file back to the repository.

Where this is configured:

- `.github/workflows/ci.yml`.

Commit pattern:

```text
ci: update auth-service image to <github.sha>
```

Concepts:

- Git as source of truth.
- Audit trail.
- Deployment traceability.
- Desired state versioning.

How we achieved it:

The workflow uses `github-actions[bot]` as the Git author and pushes the commit.

Other ways:

- Open a pull request for the image tag change.
- Commit to a separate deployment repository.
- Use Argo CD Image Updater to write back.
- Promote by copying image digest from dev values to staging/prod values.

### 14. Argo CD Watches Git Repository

What happens:

Argo CD continuously compares the desired state in Git with the live state in the Kubernetes cluster.

Where this is configured:

- `kubernetes/argocd/application.yaml`.

Important values:

```yaml
source:
  repoURL: https://github.com/gopalakrishnachennu/medflow.git
  targetRevision: main
  path: kubernetes/helm-charts/medflow
  helm:
    valueFiles:
      - values-dev.yaml
destination:
  namespace: medflow-dev
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

Concepts:

- GitOps controller.
- Drift detection.
- Automated sync.
- Self-healing.
- Pruning deleted resources.

How we achieved it:

The `medflow-dev` Argo CD Application points at the Helm chart path and applies `values-dev.yaml` into the `medflow-dev` namespace.

Other ways:

- Flux CD.
- GitHub Actions direct Helm deployment.
- Spinnaker.
- AWS CodePipeline with EKS deploy actions.

### 15. Argo CD Detects New Commit

What happens:

After GitHub Actions commits a new image tag, Argo CD sees the application is `OutOfSync`.

Concepts:

- Desired vs live diff.
- OutOfSync state.
- Reconciliation queue.

How we achieved it:

The Application has automated sync enabled. Argo CD either detects the change by polling Git or through webhook integration if configured in the cluster.

Other ways:

- Manual sync from Argo CD UI.
- CLI sync from CI.
- Webhook-triggered refresh.
- App-of-apps pattern.

### 16. Argo CD Syncs Kubernetes Cluster

What happens:

Argo CD renders the Helm chart and applies Kubernetes manifests to EKS.

Where this is configured:

- `kubernetes/helm-charts/medflow/templates/`.

Rendered resource types:

- Deployment.
- Service.
- Ingress.
- ConfigMap.
- ServiceAccount.
- HorizontalPodAutoscaler.
- PodDisruptionBudget.
- NetworkPolicy.

Concepts:

- Helm templating.
- Kubernetes declarative manifests.
- Server-side reconciliation.
- Environment overlays.

How we achieved it:

The chart loops over `.Values.services` and creates a Deployment and Service for each enabled service.

Other ways:

- Kustomize overlays.
- Raw Kubernetes YAML.
- Jsonnet/Tanka.
- CDK8s.
- Pulumi Kubernetes.

### 17. Kubernetes Deployment Starts Rolling Update

What happens:

When the Deployment image tag changes, Kubernetes creates a new ReplicaSet and gradually replaces old pods with new pods.

Where this is configured:

- `kubernetes/helm-charts/medflow/templates/deployment.yaml`.

Concepts:

- Deployment.
- ReplicaSet.
- Rolling update.
- Pod lifecycle.
- Declarative scheduling.

How we achieved it:

The Deployment image field is generated from:

```text
{{ global.imageRegistry }}{{ service.image.repository }}:{{ service.image.tag }}
```

Changing the tag changes the pod template hash, which triggers a rollout.

Other ways:

- Blue-green deployment.
- Canary deployment.
- Recreate deployment.
- StatefulSet for stateful workloads.
- Argo Rollouts for advanced progressive delivery.

### 18. New Pods Start and Pull Image from ECR

What happens:

Kubernetes schedules new pods. The node pulls the image from ECR and starts the container.

Where this is configured:

- ECR registry in `values-dev.yaml`.
- Image repository and tag in `values-dev.yaml`.
- EKS from Terraform module.

Concepts:

- Pod scheduling.
- Container runtime.
- Image pull.
- IAM permissions for ECR.
- EKS worker nodes.

How we achieved it:

`global.imageRegistry` points to the AWS ECR registry:

```yaml
global:
  imageRegistry: 724476121315.dkr.ecr.us-east-2.amazonaws.com/
```

Other ways:

- Pull from public registry.
- Use private registry image pull secrets.
- Mirror images into an internal registry.
- Use image digest instead of tag for stronger immutability.

### 19. Health Checks Run

What happens:

Kubernetes checks whether the container is alive and ready for traffic.

Where this is configured:

- `kubernetes/helm-charts/medflow/templates/deployment.yaml`.
- Backend Dockerfiles include a Docker `HEALTHCHECK`.

Kubernetes probes:

```yaml
readinessProbe:
  httpGet:
    path: /health
livenessProbe:
  httpGet:
    path: /health
```

Concepts:

- Readiness probe.
- Liveness probe.
- Startup validation.
- Zero-downtime rollout.
- Self-healing.

How we achieved it:

Every service container exposes `/health`, and the Helm chart uses that path for probes.

Other ways:

- Add `startupProbe` for slow-starting applications.
- Use gRPC probes.
- Use command probes.
- Use separate deep health and shallow health endpoints.

### 20. Kubernetes Service Routes Traffic

What happens:

The Kubernetes Service sends traffic only to pods matching its selector.

Where this is configured:

- `kubernetes/helm-charts/medflow/templates/service.yaml`.

Concepts:

- Service discovery.
- ClusterIP.
- LoadBalancer.
- Endpoint selection.
- Stable virtual IP.

How we achieved it:

Each service gets a Kubernetes Service with:

```yaml
selector:
  app.kubernetes.io/component: <service-name>
```

Other ways:

- Headless Service.
- ExternalName Service.
- Service mesh traffic routing.
- Direct pod routing is not recommended.

### 21. Ingress, Kong, and Istio Route Traffic

What happens:

External or API traffic enters the cluster through an ingress layer.

Where this is configured:

- Helm Ingress: `kubernetes/helm-charts/medflow/templates/ingress.yaml`.
- Kong: `kubernetes/kong/kong-ingress.yaml`.
- Kong rate limiting: `kubernetes/kong/rate-limiting-plugin.yaml`.
- Istio gateway and virtual service: `kubernetes/istio/`.

Kong current example:

```yaml
ingressClassName: kong
annotations:
  konghq.com/plugins: medflow-rate-limit
```

Istio current example:

```yaml
match:
  - uri:
      prefix: /auth
route:
  - destination:
      host: auth-service
      subset: blue
    weight: 100
  - destination:
      host: auth-service
      subset: green
    weight: 0
```

Concepts:

- Ingress controller.
- API gateway.
- Rate limiting.
- Service mesh.
- mTLS.
- Traffic splitting.
- Blue-green deployment.

How we achieved it:

MedFlow includes both gateway patterns:

- Kong handles API gateway style ingress and rate limiting.
- Istio handles service mesh traffic control, mTLS, and blue-green/canary routing.

Other ways:

- AWS Application Load Balancer Controller.
- NGINX Ingress Controller.
- Traefik.
- Envoy Gateway.
- Linkerd service mesh.
- AWS API Gateway in front of EKS.

### 22. Deployment Completed

What happens:

The new version is live when:

- Argo CD reports the application is synced.
- Kubernetes Deployment rollout completes.
- Pods are ready.
- Post-deployment smoke tests pass.

Where this is configured:

- `.github/workflows/cd.yml`.

Dev smoke test:

```bash
curl -sf http://auth-service/health
```

Concepts:

- Health gate.
- Smoke testing.
- Deployment verification.
- Release confidence.

How we achieved it:

The CD workflow logs into Argo CD, syncs `medflow-dev`, waits for health, and runs a simple in-cluster curl test.

Other ways:

- Synthetic checks from outside the cluster.
- API contract tests.
- Browser end-to-end tests.
- Load tests.
- Argo Rollouts analysis templates.

## CD Pipeline Details

The CD workflow is in `.github/workflows/cd.yml`.

### Dev Deployment

Trigger:

- Automatically after CI succeeds on `main`.
- Manually with `workflow_dispatch` and environment `dev`.

Flow:

```text
checkout
  -> configure AWS credentials through OIDC
  -> aws eks update-kubeconfig for medflow-dev
  -> install Argo CD CLI
  -> argocd app sync medflow-dev
  -> argocd app wait medflow-dev --health
  -> run auth-service smoke test
```

### Staging Deployment

Trigger:

- Manual workflow dispatch with environment `staging`.

Additional step:

- Runs Alembic database migrations as a Kubernetes Job before Argo CD sync.

Concepts:

- Manual promotion.
- Environment approvals.
- Migration job.
- Pre-deployment database change.

### Production Deployment

Trigger:

- Manual workflow dispatch with environment `prod`.

Strategy:

- Blue-green deployment using Istio.
- Deploy green version alongside blue.
- Send 10 percent traffic to green.
- Observe error rate from Prometheus.
- Shift 100 percent traffic to green if healthy.
- Roll back to blue if error rate exceeds 1 percent.

Concepts:

- Production approval.
- Blue-green deployment.
- Canary validation.
- Automated rollback.
- Metrics-based promotion.
- Slack notification.

## Helm Chart Explanation

The Helm chart is at:

```text
kubernetes/helm-charts/medflow/
```

Chart metadata:

```yaml
apiVersion: v2
name: medflow
version: 0.1.0
appVersion: "0.1.0"
```

Main values files:

- `values.yaml`: base defaults.
- `values-dev.yaml`: dev environment and ECR image tags.
- `values-staging.yaml`: staging overrides.
- `values-prod.yaml`: production overrides.

The chart uses a service map:

```yaml
services:
  auth:
    enabled: true
    name: auth-service
    image:
      repository: medflow/auth-service
      tag: <sha>
```

What Helm creates:

```text
for each enabled service:
  Deployment
  Service
  HPA
  PDB

shared:
  ConfigMap
  ServiceAccount
  Ingress
  NetworkPolicies
```

Security controls in the chart:

- `runAsNonRoot: true`.
- `runAsUser: 10001`.
- `seccompProfile: RuntimeDefault`.
- `allowPrivilegeEscalation: false`.
- `readOnlyRootFilesystem: true`.
- Drop all Linux capabilities.
- Mount `/tmp` as `emptyDir` because root filesystem is read-only.

## Kubernetes Runtime Explanation

MedFlow uses Kubernetes concepts as follows:

| Kubernetes Concept | MedFlow Usage |
|---|---|
| Namespace | `medflow-dev` isolates dev workloads. |
| Deployment | Runs stateless service pods. |
| ReplicaSet | Created by Deployment during rollout. |
| Pod | Smallest runtime unit for each service container. |
| Service | Stable networking endpoint for pods. |
| Ingress | External HTTP routing into services. |
| ConfigMap | Non-secret environment config. |
| Secret | Database URLs and JWT secrets are generated by External Secrets Operator from AWS Secrets Manager, then referenced through `secretEnv`. |
| ServiceAccount | Identity assigned to pods. |
| HPA | Scales service replicas based on CPU utilization. |
| PDB | Keeps minimum pods available during voluntary disruptions. |
| NetworkPolicy | Restricts pod ingress/egress. |
| Probes | Readiness and liveness health checking. |

## Infrastructure as Code Explanation

Terraform defines AWS infrastructure for dev:

```text
infrastructure/environments/dev
  -> vpc
  -> ecr
  -> github_oidc
  -> budget
  -> eks
  -> rds
```

Key modules:

| Module | Purpose |
|---|---|
| `vpc` | Networking foundation and private subnets. |
| `ecr` | Container repositories for all services. |
| `github-oidc` | IAM trust between GitHub Actions and AWS. |
| `eks` | Kubernetes runtime cluster. |
| `rds` | Managed PostgreSQL database. |
| `external-secrets-irsa` | IAM role for External Secrets Operator to read approved AWS Secrets Manager entries. |
| `elasticache` | Managed Redis, available as a module. |
| `s3` | Object storage module. |
| `budget` | AWS budget guardrail for lab cost control. |

Terraform state:

```yaml
backend "s3" {
  bucket         = "medflow-terraform-state-1fd2a736"
  key            = "dev/terraform.tfstate"
  region         = "us-east-2"
  dynamodb_table = "medflow-terraform-locks"
  encrypt        = true
}
```

Concepts:

- Remote state.
- State locking.
- Modular Terraform.
- Environment directory pattern.
- Least privilege IAM.
- Cloud cost guardrails.

## Security Architecture

Security is layered:

```text
Code layer:
  linting, tests, dependency scanning, secret scanning

Build layer:
  Dockerfile hardening, non-root user, image scanning, SBOM

Registry layer:
  ECR encryption, immutable tags, scan on push, lifecycle policy

Kubernetes layer:
  Pod Security Admission, NetworkPolicy, restricted securityContext

Service mesh layer:
  Istio mTLS and traffic policy

Cloud layer:
  IAM roles, OIDC, IRSA, AWS Secrets Manager, private subnets, RDS security group

Compliance layer:
  HIPAA checklist, audit log config, encryption policy
```

Files:

- `security/policies/pod-security-admission.yaml`.
- `security/policies/network-policies.yaml`.
- `security/policies/opa-policies/deny-privileged.rego`.
- `security/compliance/hipaa-checklist.md`.
- `security/compliance/encryption-policy.md`.
- `security/compliance/audit-log-config.yaml`.
- `kubernetes/external-secrets/cluster-secret-store.yaml`.
- `kubernetes/external-secrets/medflow-dev-external-secret.yaml`.
- `infrastructure/modules/external-secrets-irsa/`.

Enterprise secret flow:

```text
AWS Secrets Manager
  -> External Secrets Operator using IRSA
  -> Kubernetes Secret medflow-real-secrets
  -> Helm Deployment secretEnv
  -> application environment variables
```

Real secret values are not committed to Git. Git stores only references to secret names, properties, and Kubernetes Secret keys.

Important note:

Code and manifests alone do not make a system HIPAA compliant. HIPAA also requires organizational controls, access reviews, audit processes, incident response, vendor agreements, training, and evidence.

## Monitoring and Logging

### Metrics

Prometheus configuration:

- `monitoring/prometheus/prometheus.yml`.
- Scrapes `/metrics`.
- Current target example: `auth-service:8000`.

Alert rules:

- `monitoring/prometheus/alert-rules.yml`.
- Current example alert: `MedFlowServiceDown` when `up == 0` for 2 minutes.

Grafana dashboards:

- `monitoring/grafana/dashboards/medflow-overview.json`.
- `monitoring/grafana/dashboards/kubernetes-cluster.json`.
- `monitoring/grafana/dashboards/patient-service.json`.

Concepts:

- Metrics scraping.
- Time-series database.
- Alerting.
- Service health dashboard.
- Golden signals.

### Logs

ELK files:

- Elasticsearch: `monitoring/elk/elasticsearch.yaml`.
- Logstash: `monitoring/elk/logstash.yaml`.
- Kibana: `monitoring/elk/kibana.yaml`.
- Filebeat: `monitoring/elk/filebeat.yaml`.

Current versions:

- Elasticsearch `8.15.3`.
- Logstash `8.15.3`.
- Filebeat `8.15.3`.

Concepts:

- Log collection.
- Log shipping.
- Centralized search.
- Container logs.
- Operational debugging.

## Post-Deployment Operations

After deployment, the DevOps team monitors:

- Pod health.
- Deployment rollout status.
- API latency.
- HTTP 5xx error rate.
- CPU and memory usage.
- Database connectivity.
- ECR image provenance.
- Argo CD sync status.
- Logs in ELK.
- Alerts in Grafana/Alertmanager.

Useful operational commands:

```bash
argocd app get medflow-dev
argocd app diff medflow-dev
argocd app sync medflow-dev

kubectl get pods -n medflow-dev
kubectl rollout status deployment/auth-service -n medflow-dev
kubectl describe pod <pod-name> -n medflow-dev
kubectl logs deployment/auth-service -n medflow-dev

helm lint kubernetes/helm-charts/medflow
helm template medflow kubernetes/helm-charts/medflow -f kubernetes/helm-charts/medflow/values-dev.yaml
```

## Rollback Methods

### GitOps Rollback

Revert the Git commit that changed the Helm image tag. Argo CD detects the revert and reconciles the cluster back to the previous image.

Best for:

- Auditable rollback.
- GitOps consistency.
- Production environments.

### Kubernetes Rollout Undo

Run:

```bash
kubectl rollout undo deployment/auth-service -n medflow-dev
```

Best for:

- Emergency recovery.

Risk:

- Can create drift from Git. Argo CD may re-apply the Git desired state unless sync is paused or Git is reverted.

### Argo CD Rollback

Use Argo CD history to roll back to a previous synced revision.

Best for:

- GitOps-aware rollback.

### Blue-Green Rollback

Patch Istio VirtualService to send traffic back to blue:

```text
blue: 100
green: 0
```

Best for:

- Fast production traffic rollback.

## Alternative Architecture Options

### CI/CD Tool Alternatives

| Current | Alternative | When to Use |
|---|---|---|
| GitHub Actions | GitLab CI | GitLab-hosted source code and integrated DevSecOps. |
| GitHub Actions | AWS CodePipeline/CodeBuild | AWS-native compliance and private VPC builds. |
| GitHub Actions | CircleCI/Buildkite | High-performance build fleet or custom runner needs. |


### Deployment Alternatives

| Current | Alternative | Tradeoff |
|---|---|---|
| Argo CD + Helm | Flux CD | Strong GitOps alternative with image automation. |
| Argo CD + Helm | GitHub Actions direct Helm deploy | Simpler but less GitOps-native. |
| Helm | Kustomize | Better for patch-style overlays; less package-oriented. |
| Rolling update | Blue-green | Faster rollback but requires extra capacity. |
| Rolling update | Canary | Lower blast radius but requires traffic metrics and routing support. |
| Istio | Linkerd | Simpler service mesh, fewer traffic management features. |
| Kong | NGINX Ingress | Simpler ingress; fewer API gateway features. |
| Kong | AWS API Gateway | Fully managed external API layer. |

### Image Tagging Alternatives

| Method | Example | Notes |
|---|---|---|
| Commit SHA | `auth-service:c040ce5` | Traceable and currently used. |
| Full SHA | `auth-service:75f9993...` | Stronger uniqueness, currently used in values. |
| Semver | `auth-service:1.4.2` | Good for release management. |
| Build number | `auth-service:build-1042` | Easy CI traceability. |
| Digest | `auth-service@sha256:...` | Strongest immutability. Recommended for production. |

### Environment Promotion Alternatives

Current dev method:

```text
CI updates values-dev.yaml directly.
```

Production-friendly method:

```text
CI builds image once
  -> dev values updated
  -> staging promotion PR copies same digest to values-staging.yaml
  -> production promotion PR copies same digest to values-prod.yaml
```

This ensures the same artifact moves through environments without rebuilding.

## What to Explain to a Manager

Use this summary:

MedFlow uses a modern DevSecOps delivery model. Developers push code to GitHub. Automated pipelines validate quality, run tests, perform security scans, build Docker images, and publish them to Amazon ECR. Deployment is controlled through GitOps: the pipeline updates Helm values in Git, and Argo CD continuously reconciles the EKS cluster to match that Git state. Kubernetes performs safe rolling updates, while readiness checks prevent traffic from going to unhealthy pods. Monitoring and logging through Prometheus, Grafana, and ELK give the team visibility after deployment. Production can use Istio blue-green deployment to reduce risk and support fast rollback.

Business benefits:

- Faster releases.
- Stronger audit trail.
- Reduced manual deployment risk.
- Security checks before release.
- Reproducible infrastructure and deployment state.
- Clear rollback path.
- Operational visibility after deployment.

## Current Gaps and Recommended Improvements

The repository has strong architecture coverage, but a few improvements would make it more production-ready:

1. Add Ruff lint and formatting checks directly to `.github/workflows/ci.yml`.
2. Pin GitHub Actions currently using `master`, `main`, or `latest`.
3. Use image digests instead of mutable-looking tags in Helm values.
4. Add `startupProbe` for services if startup becomes slow.
5. Expand Prometheus scrape config for all services, not only auth.
6. Add ServiceMonitors if using Prometheus Operator.
7. Complete External Secrets rollout for staging and prod and remove any manual Kubernetes Secret creation.
8. Add staging and production Argo CD Application manifests.
9. Add pull-request based promotion for staging and prod.
10. Add policy-as-code enforcement with Kyverno or Gatekeeper.
11. Add end-to-end tests and smoke tests for every exposed route.
12. Add documented incident response and rollback runbooks per service.

## Full Numbered Workflow Matching the Architecture Diagram

### 1. Developer

The developer writes application, infrastructure, or configuration code. The developer validates locally with `make test`, `make lint`, or `make validate`.

### 2. GitHub Repository

The developer pushes code to GitHub. GitHub stores source code, pipeline definitions, Helm values, and GitOps desired state.

### 3. GitHub Actions Triggered

Pushes and pull requests trigger `.github/workflows/ci.yml`. Security checks also run from `.github/workflows/security.yml`.

### 4. Code Quality Checks

Ruff is available in the repo for Python linting. SonarQube configuration files are present per service. In production, this should be enforced as a required CI job.

### 5. Test Stage

Pytest runs per changed Python service. Coverage XML is uploaded to Codecov.

### 6. Security Scan Stage

Dependency Check, Gitleaks, Checkov, tfsec, Kubescape, Trivy, and Syft cover dependencies, secrets, Terraform, Kubernetes, images, and SBOMs.

### 7. Docker Build Stage

Docker Buildx builds service images from Dockerfiles. Images are tagged with the Git commit SHA.

### 8. Trivy Image Scan

Trivy scans the built image and uploads SARIF to GitHub Security.

### 9. Push Image to Amazon ECR

The image is pushed to ECR repositories created by Terraform. ECR provides registry storage, encryption, scan-on-push, and lifecycle retention.

### 10. Update Helm Values

The Python script updates the image tag in `values-dev.yaml`.

### 11. Commit Updated Helm Values to Git

GitHub Actions commits the updated values file. This commit is the deployment request.

### 12. Argo CD Watches Git Repository

The Argo CD Application watches the Helm chart path on the `main` branch.

### 13. Argo CD Detects New Commit

Argo CD marks the app OutOfSync when the Git image tag differs from the live cluster state.

### 14. Argo CD Syncs Kubernetes Cluster

Argo CD renders Helm templates and applies Kubernetes manifests to the target namespace.

### 15. Kubernetes Deployment Starts Rolling Update

Kubernetes creates a new ReplicaSet because the Deployment pod template changed.

### 16. New Pods Start

Pods pull the new image from ECR and start on EKS worker nodes.

### 17. Health Checks Run

Readiness and liveness probes call `/health`. Unready pods do not receive Service traffic.

### 18. Kubernetes Service Routes Traffic

The Service selects ready pods and provides stable in-cluster DNS such as `auth-service`.

### 19. Ingress / Kong Gateway Routes External Traffic

Ingress or Kong routes HTTP traffic into services. Istio can route by URI and split traffic between blue and green subsets.

### 20. Deployment Completed

Deployment is complete when Argo CD is synced and healthy, Kubernetes rollout succeeds, and smoke tests pass.

### 21. Prometheus Collects Metrics

Prometheus scrapes `/metrics` endpoints and evaluates alert rules.

### 22. Logs Go to ELK

Filebeat collects container logs and sends them through the ELK pipeline for searching and debugging.

### 23. Grafana Dashboards and Alerts

Grafana visualizes service and cluster health. Alertmanager routes alerts to the team.

### 24. DevOps Team Monitors and Debugs

The team investigates alerts, reviews Argo CD state, checks Kubernetes events/logs, rolls back if needed, and improves the platform.

## Final Reference Diagram

```text
                           MEDFLOW CI/CD + GITOPS ARCHITECTURE

Developer
  |
  | writes code, commits, pushes
  v
GitHub Repository
  |
  | push / pull_request / workflow_dispatch
  v
+--------------------------------------------------------------------------------+
| GitHub Actions CI                                                              |
|                                                                                |
|  detect changes                                                                |
|      -> test changed services                                                  |
|      -> upload coverage                                                        |
|      -> dependency/security scans                                              |
|      -> AWS OIDC authentication                                                |
|      -> Docker Buildx build                                                    |
|      -> push image to ECR                                                      |
|      -> Trivy image scan                                                       |
|      -> update Helm values-dev.yaml                                            |
|      -> commit desired state to Git                                            |
+--------------------------------------------------------------------------------+
  |
  | image artifact
  v
Amazon ECR
  |
  | image reference in Git
  v
Git desired state: Helm chart + values-dev.yaml
  |
  | watched by
  v
+--------------------------------------------------------------------------------+
| Argo CD                                                                        |
|                                                                                |
|  compare Git desired state with live EKS state                                 |
|      -> render Helm                                                            |
|      -> sync manifests                                                         |
|      -> prune removed resources                                                |
|      -> self-heal drift                                                        |
+--------------------------------------------------------------------------------+
  |
  v
+--------------------------------------------------------------------------------+
| Amazon EKS / Kubernetes                                                        |
|                                                                                |
|  Deployment -> ReplicaSet -> Pods                                              |
|  ConfigMap + Secrets -> environment                                            |
|  Readiness/Liveness probes -> healthy endpoints                                |
|  Service -> stable internal routing                                            |
|  HPA -> CPU-based scaling                                                      |
|  PDB -> availability during disruptions                                        |
|  NetworkPolicy + Pod Security -> runtime hardening                             |
+--------------------------------------------------------------------------------+
  |
  v
+--------------------------------------------------------------------------------+
| Traffic Layer                                                                  |
|                                                                                |
|  Ingress / Kong API Gateway -> external API routing and rate limiting          |
|  Istio Gateway / VirtualService -> mTLS, blue-green, canary traffic splitting  |
+--------------------------------------------------------------------------------+
  |
  v
+--------------------------------------------------------------------------------+
| Observability                                                                  |
|                                                                                |
|  Prometheus -> metrics                                                         |
|  Grafana -> dashboards                                                         |
|  Alertmanager -> alerts                                                        |
|  Filebeat -> Logstash -> Elasticsearch -> Kibana -> logs                       |
+--------------------------------------------------------------------------------+
  |
  v
DevOps continuous improvement:
  incidents, rollback, tuning, cost optimization, security hardening, automation
```
