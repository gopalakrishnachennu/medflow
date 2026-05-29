# External Secrets for MedFlow

MedFlow uses AWS Secrets Manager as the enterprise source of truth for runtime application secrets.

Flow:

```text
AWS Secrets Manager
  -> External Secrets Operator
  -> Kubernetes Secret medflow-real-secrets
  -> Helm Deployment secretEnv
  -> application environment variables
```

Apply order:

1. Provision AWS infrastructure with Terraform.
2. Get the `external_secrets_role_arn` Terraform output.
3. Replace `<EXTERNAL_SECRETS_ROLE_ARN>` in `kubernetes/argocd/external-secrets-application.yaml`.
4. Add the `/medflow/dev/app` key/value pairs in AWS Secrets Manager.
5. Apply the Argo CD Application for External Secrets Operator.
6. Apply the `medflow-dev` namespace manifest.
7. Apply `cluster-secret-store.yaml`.
8. Apply `medflow-dev-external-secret.yaml`.

The manifests in this directory do not contain real secret values. They only reference AWS Secrets Manager names and properties.

Expected AWS Secrets Manager entries:

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

Terraform creates the RDS credential secret and an empty app runtime secret. Add the app runtime key/value pairs directly in AWS Secrets Manager or through an approved secure process.

Example secure setup command for the app runtime secret:

```bash
aws secretsmanager put-secret-value \
  --secret-id /medflow/dev/app \
  --secret-string '{"jwt-secret-key":"REPLACE_WITH_APPROVED_VALUE","jwt-algorithm":"HS256","access-token-expire-minutes":"30"}'
```

Do not commit the real values used in that command.
