# MedFlow Implementation Plan

This plan turns the original MedFlow structure into a careful build sequence. The project should not be implemented by creating every file at once. Each phase must produce a working, testable result.

## Plan Review

The original plan is strong because it covers application code, infrastructure, Kubernetes, CI/CD, monitoring, security, and operations. That is exactly what an advanced DevOps project should include.

The main risk is scope. A full healthcare microservices platform with EKS, Istio, Kong, Argo CD, GitHub Actions, ELK, Prometheus, HIPAA-style compliance, and disaster recovery is too much to build safely as a single pass. The correct approach is phased implementation with working checkpoints.

## Corrections to the Original Plan

- Replace `pod-security-policies.yaml` with Pod Security Admission labels plus OPA/Gatekeeper or Kyverno policies. Kubernetes PodSecurityPolicy is removed.
- Do not commit real Kubernetes Secrets. Use placeholders for learning and use a secret manager in real deployments.
- Keep Kong and Istio responsibilities clear. Kong handles north-south API gateway concerns; Istio handles east-west service mesh traffic, mTLS, retries, and traffic splitting.
- Use one deployment system as the source of truth. CI builds images and updates Git; Argo CD applies cluster state.
- Treat HIPAA as a learning theme, not a compliance claim.
- Keep Terraform modules small and reusable. Avoid one giant environment file.

## Phase 0: Foundation

Deliverables:

- Repository structure
- README
- Architecture documentation
- Implementation plan
- Runbook
- DevOps concept notes

Validation:

- A learner can explain what each folder is for.
- A learner can explain the end-to-end delivery path from code commit to production deployment.

## Phase 1: Local Application Foundation

Deliverables:

- `auth-service` FastAPI app
- PostgreSQL and Redis with Docker Compose
- Local health endpoint
- Register and login endpoints
- Unit tests
- Makefile commands

Validation:

```bash
make test
make dev
curl http://localhost:8001/health
```

## Phase 2: Domain Services

Deliverables:

- `patient-service`
- `appointment-service`
- `records-service`
- `billing-service`
- `pharmacy-service`
- `notification-service`
- Service-to-service API contracts
- Database migration strategy

Validation:

- Each service has a health endpoint.
- Each service has tests.
- Compose can start the full local platform.

## Phase 3: Containers and DevSecOps Scanning

Deliverables:

- Dockerfile per service
- Non-root runtime users
- `.dockerignore` files
- Trivy image scanning
- SBOM generation

Validation:

```bash
docker compose build
trivy image medflow-auth-service
```

## Phase 4: Kubernetes Baseline

Deliverables:

- Namespace
- Deployment
- Service
- ConfigMap
- Secret placeholder
- Ingress
- HPA
- NetworkPolicy

Validation:

```bash
kubectl apply --dry-run=server -f kubernetes/
```

## Phase 5: Helm

Deliverables:

- Generic service templates
- Dev, staging, and prod values
- Resource limits and probes
- Autoscaling values

Validation:

```bash
helm lint kubernetes/helm-charts/medflow
helm template medflow kubernetes/helm-charts/medflow -f kubernetes/helm-charts/medflow/values-dev.yaml
```

## Phase 6: AWS Infrastructure with Terraform

Deliverables:

- VPC module
- EKS module
- RDS module
- ECR module
- S3 module
- ElastiCache module
- CloudWatch module
- Dev environment composition

Validation:

```bash
terraform fmt -recursive
terraform validate
checkov -d infrastructure
```

## Phase 7: CI/CD

Deliverables:

- GitHub Actions CI
- GitHub Actions security workflow
- Image build and push workflow

Validation:

- Pull request runs tests and scans.
- Main branch builds and publishes images.
- Deployment changes are GitOps-controlled.

## Phase 8: GitOps with Argo CD

Deliverables:

- Argo CD project
- App-of-apps
- Environment applications
- Sync policies

Validation:

- Argo CD detects Git changes.
- Argo CD syncs dev automatically.
- Staging and prod require promotion gates.

## Phase 9: Security and Compliance

Deliverables:

- OPA policies
- Network policies
- Pod Security Admission labels
- Audit logging config
- Encryption policy
- HIPAA-inspired checklist

Validation:

- Privileged pods are denied.
- Services cannot talk across boundaries unless allowed.
- Security scan reports are produced in CI.

## Phase 10: Observability

Deliverables:

- Prometheus config
- Alert rules
- Grafana dashboards
- Alertmanager routes
- ELK/Filebeat log collection

Validation:

- Service health and latency are visible.
- Kubernetes resource usage is visible.
- Alerts fire for simulated failures.

## Phase 11: Advanced Delivery

Deliverables:

- Istio gateway
- VirtualService
- DestinationRule
- mTLS PeerAuthentication
- Blue-green deployment example

Validation:

- Traffic can be shifted between blue and green versions.
- mTLS is enforced inside the mesh.

## Phase 12: Operations

Deliverables:

- Backup scripts
- Restore scripts
- Disaster recovery runbook
- Cost cleanup scripts
- Cost report Lambda

Validation:

- A database backup can be restored in a test environment.
- DR steps are documented and rehearsed.
- Cost report can identify unused resources.

