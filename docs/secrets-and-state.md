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

The Helm chart currently contains placeholder secret values in:

```text
kubernetes/helm-charts/medflow/templates/secrets.yaml
```

These are not real secrets. For an AWS deployment, replace this with one of:

- AWS Secrets Manager + External Secrets Operator
- SOPS-encrypted secrets
- Sealed Secrets

Preferred enterprise path: AWS Secrets Manager + External Secrets Operator.

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

