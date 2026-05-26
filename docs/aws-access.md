# AWS Access Guide

Do not paste AWS access keys into chat, code, screenshots, or documentation.

Use one of these enterprise-safe access patterns:

## Local Development

Preferred:

```bash
aws configure sso --profile medflow-dev
aws sso login --profile medflow-dev
export AWS_PROFILE=medflow-dev
```

Fallback for learning labs:

```bash
aws configure --profile medflow-dev
export AWS_PROFILE=medflow-dev
```

If using access keys, create a dedicated IAM user with least privilege and rotate/delete the keys after the lab.

Check whether the profile exists:

```bash
aws configure list-profiles
```

Verify the profile:

```bash
aws sts get-caller-identity --profile medflow-dev
```

## GitHub Actions

Use GitHub OIDC to assume an AWS IAM role. Do not store long-lived AWS keys in GitHub secrets.

MedFlow defines this role in Terraform:

```text
infrastructure/modules/github-oidc
```

After applying Terraform, store the output as a GitHub repository variable:

```bash
terraform -chdir=infrastructure/environments/dev output github_actions_role_arn
```

GitHub variable name:

```text
AWS_GITHUB_OIDC_ROLE_ARN
```

For this project, the default AWS region is:

```text
us-east-2
```

Required role trust policy should allow:

- repository-specific subject claims
- selected branch/environment only
- short-lived STS credentials

## Terraform State

Use a remote backend:

- S3 bucket with versioning and encryption
- DynamoDB table for state locking
- restricted IAM access
- separate state path per environment

## Environment Separation

Use separate AWS accounts where possible:

- shared-services
- dev
- staging
- prod

At minimum, use separate IAM roles and Terraform state files for each environment.
