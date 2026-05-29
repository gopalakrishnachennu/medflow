# Secrets and Terraform State

## Current Local Secrets

Local-only development values are loaded from `.env`.

Create it from the example file:

```bash
cp .env.example .env
```

The `.env` file is ignored by Git and must not be committed.

Current local variables:

- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `AUTH_DATABASE_URL`
- `AUTH_JWT_SECRET_KEY`
- `AUTH_JWT_ALGORITHM`
- `AUTH_ACCESS_TOKEN_EXPIRE_MINUTES`

## Application Password Storage

User passwords are never stored as plaintext by the auth service.

Flow:

1. `/auth/register` receives a password.
2. `app/auth.py` hashes it with `passlib` + bcrypt.
3. The hash is stored in the `users.hashed_password` column.
4. Login verifies the submitted password against the hash.

## Kubernetes Secrets

The Helm chart does not store real secret values. It only references Kubernetes Secret names and keys through `secretEnv` in the values files.

```text
kubernetes/helm-charts/medflow/values-dev.yaml
kubernetes/helm-charts/medflow/templates/deployment.yaml
```

Current runtime secret expected by the Helm chart:

```text
medflow-real-secrets
  database-url
  jwt-secret-key
  jwt-algorithm
  access-token-expire-minutes
```

Preferred enterprise path: AWS Secrets Manager + External Secrets Operator.

Flow:

```text
AWS Secrets Manager
  -> External Secrets Operator
  -> Kubernetes Secret medflow-real-secrets
  -> Helm Deployment secretEnv
  -> application environment variables
```

Supporting files:

```text
kubernetes/argocd/external-secrets-application.yaml
kubernetes/external-secrets/cluster-secret-store.yaml
kubernetes/external-secrets/medflow-dev-external-secret.yaml
infrastructure/modules/external-secrets-irsa/
```

AWS Secrets Manager entries expected for dev:

```text
dev/medflow-dev-db/credentials
  username
  password
  engine
  dbname
  host
  port

/medflow/dev/app
  jwt-secret-key
  jwt-algorithm
  access-token-expire-minutes
```

Terraform creates the RDS credential secret and an empty app runtime secret. The actual app runtime values must be added in AWS Secrets Manager through an approved secure process, not committed to Git.

## AWS Credentials

Do not store AWS access keys in this repository.

Use:

```bash
aws configure sso
aws sso login --profile medflow-dev
export AWS_PROFILE=medflow-dev
```

For GitHub Actions, use GitHub OIDC to assume an AWS IAM role. Do not use long-lived AWS keys in GitHub secrets.

## Terraform State

No Terraform state file is currently committed.

The local `.terraform/` directory contains downloaded providers and is ignored by Git.

The lock file is safe and should be committed:

```text
infrastructure/environments/dev/.terraform.lock.hcl
```

Before running `terraform apply` against AWS, configure a remote backend:

- S3 bucket for state
- DynamoDB table for locking
- KMS encryption
- versioning enabled
- separate state key per environment

Current backend template:

```text
infrastructure/environments/dev/backend.tf
```

Until that backend is enabled, Terraform would create local state at:

```text
infrastructure/environments/dev/terraform.tfstate
```

Do not commit `terraform.tfstate` or `*.tfstate.*`.
