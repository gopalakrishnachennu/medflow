# MedFlow Architecture

## High-Level Flow

1. Users access the frontend through CloudFront.
2. CloudFront routes API traffic to Kong through an ingress/load balancer.
3. Kong validates gateway-level policies such as rate limiting.
4. Traffic enters Kubernetes services running on EKS.
5. Istio manages internal service-to-service traffic, mTLS, retries, and traffic splitting.
6. Services store transactional data in PostgreSQL.
7. Services use Redis for caching and workflow coordination.
8. Records-service stores document objects in S3 and stores metadata in PostgreSQL.
9. Prometheus scrapes service and cluster metrics.
10. Filebeat ships logs into the ELK stack.
11. Argo CD continuously reconciles Kubernetes desired state from Git.

## Service Boundaries

| Service | Responsibility | Owns Data |
|---|---|---|
| Auth | Users, roles, JWT | users |
| Patient | Demographics, profile | patients |
| Appointment | Scheduling | appointments |
| Records | Medical record metadata | records |
| Pharmacy | Prescriptions | prescriptions |
| Billing | Invoices and payments | invoices, payments |
| Notification | Email/SMS-style messages | notifications |

Each service should own its database tables. Cross-service access should happen through APIs or events, not direct table access.

## Deployment Model

- `dev`: fast iteration, smaller node group, auto-sync allowed
- `staging`: production-like, promotion from dev, stricter scans
- `prod`: manual approval, restricted access, multi-AZ resources

## Security Model

- JWT for end-user authentication
- RBAC claims in tokens
- Kubernetes RBAC for cluster access
- IAM roles for AWS access
- mTLS between services through Istio
- NetworkPolicy for namespace traffic restrictions
- WAF and rate limiting at the edge/API gateway
- Encryption in transit and at rest
- Audit logs for sensitive operations

## Observability Model

Golden signals:

- Latency
- Traffic
- Errors
- Saturation

Key dashboards:

- Platform overview
- Kubernetes cluster
- Service health
- API gateway
- CI/CD pipeline
- Database health

