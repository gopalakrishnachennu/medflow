# Enterprise Readiness

MedFlow is being built toward enterprise-grade practices in phases.

## Implemented Enterprise Controls

- Root-level GitHub Actions workflows
- Least-privilege workflow permissions
- Trusted-runner image build workflow
- GitHub Actions OIDC role Terraform module
- ECR push permissions scoped to MedFlow repositories
- GitOps image tag promotion workflow
- No-Docker local auth-service workflow
- Non-root service container
- Container healthcheck
- Readiness endpoint
- Prometheus metrics endpoint
- Structured JSON logs
- Helm service account
- Pod and container security contexts
- Read-only container root filesystem
- PodDisruptionBudget
- Default-deny NetworkPolicy baseline
- Multi-AZ VPC baseline
- ECR immutable tags
- ECR scan-on-push
- ECR lifecycle cleanup
- Terraform validation-ready dev environment

## Still Required Before Calling This Production Grade

- Real EKS module
- Real RDS module with encryption, backup, subnet group, parameter group, and alarms
- Secrets Manager or External Secrets Operator
- Apply Terraform and configure GitHub repository variables
- Argo CD connected to a real cluster
- Full service implementations beyond auth-service
- Production Grafana dashboards and alerts
- Centralized log retention policy
- CI image build/push to ECR
- Kubernetes admission policy enforcement
- Disaster recovery restore test
- Security threat model and evidence collection

## AWS Credential Rule

Never share long-lived AWS keys in chat. Use AWS SSO locally and GitHub OIDC in CI/CD.
