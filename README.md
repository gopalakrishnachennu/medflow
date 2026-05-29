# MedFlow

MedFlow is an advanced healthcare DevSecOps capstone project. It is designed to teach the complete lifecycle of a modern cloud-native system: application code, containers, Kubernetes, infrastructure as code, CI/CD, GitOps, security, observability, disaster recovery, and cost operations.

## Architecture Summary

MedFlow uses a microservices architecture:

- `auth-service`: login, JWT issuing, role-based access
- `patient-service`: patient demographics and profile data
- `appointment-service`: appointment scheduling workflow
- `records-service`: medical record metadata and document references
- `pharmacy-service`: prescription workflow
- `billing-service`: invoices, payments, and claim-like records
- `notification-service`: email/SMS-style event notifications
- `frontend`: web interface for patients and staff

Shared platform services:

- PostgreSQL for transactional data
- Redis for caching and async workflow coordination
- S3 for object storage
- ECR for container images
- EKS for Kubernetes runtime
- RDS for managed PostgreSQL
- ElastiCache for managed Redis
- CloudFront and WAF for edge delivery and protection

## Current Implementation Status

This repository starts with Phase 0 and Phase 1 foundations:

- Project structure
- Implementation roadmap
- Architecture documentation
- Local Docker Compose stack
- Runnable FastAPI `auth-service`
- Starter tests
- Starter Kubernetes, Terraform, CI/CD, security, monitoring, and operations files

## Local Development

```bash
make dev
```

Services:

- Auth API: `http://localhost:8001`
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`

Run tests:

```bash
make test
```

Stop local services:

```bash
make down
```

## Recommended Build Order

1. Finish `auth-service` with database-backed users and JWT tests.
2. Add `patient-service` and connect it to auth claims.
3. Add service Dockerfiles and local compose integration.
4. Add Helm chart deployment for one service.
5. Generalize Helm templates for all services.
6. Build Terraform dev environment.
7. Add CI/CD pipelines.
8. Add Argo CD sync.
9. Add monitoring and alerting.
10. Add security policies and compliance evidence.

## Important Design Notes

- Do not use Kubernetes `PodSecurityPolicy`; it was removed from Kubernetes. Use Pod Security Admission labels and policy tools such as OPA/Gatekeeper or Kyverno.
- Do not store real secrets in Git. Use AWS Secrets Manager, External Secrets Operator, Sealed Secrets, or SOPS in real deployments.
- Do not claim HIPAA compliance from code alone. Compliance requires policies, access controls, audits, training, vendor agreements, and operational evidence.

## Enterprise Notes

- [CI/CD and GitOps Architecture Deep Dive](docs/cicd-gitops-architecture-deep-dive.md)
- [Enterprise Readiness](docs/enterprise-readiness.md)
- [Enterprise Delivery Model](docs/enterprise-delivery.md)
- [AWS Access Guide](docs/aws-access.md)
- [AWS Account Profile](docs/aws-account-profile.md)
- [Secrets and Terraform State](docs/secrets-and-state.md)
