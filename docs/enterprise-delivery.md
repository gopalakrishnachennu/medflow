# Enterprise Delivery Model

MedFlow is designed so developers do not need Docker on their laptops.

## Developer Laptop

Developers run code and tests only:

```bash
make venv
make install
make test
make run-auth-local
```

Docker Compose remains optional for local learning, but it is not the source of production images.

## Trusted CI

GitHub Actions is the trusted build system.

Flow:

1. Developer pushes code.
2. CI runs tests, lint, Helm render, Terraform validation.
3. Image build workflow builds the container on a GitHub-hosted runner.
4. Trivy scans the image.
5. GitHub Actions assumes an AWS role through OIDC.
6. The image is pushed to Amazon ECR.

No long-lived AWS access keys are stored in GitHub.

## GitOps CD

Deployment does not happen directly from the developer laptop.

Flow:

1. CD workflow updates the Helm environment values file with the approved image tag.
2. The workflow commits the GitOps change.
3. Argo CD detects the Git change.
4. Argo CD reconciles EKS to match Git.

## Required GitHub Repository Variables

Configure these after Terraform creates the OIDC role:

- `AWS_REGION`
- `AWS_GITHUB_OIDC_ROLE_ARN`

The role ARN is output by Terraform:

```bash
terraform -chdir=infrastructure/environments/dev output github_actions_role_arn
```

## Required AWS Foundation

Before enabling image builds:

1. Configure AWS SSO locally.
2. Apply the dev Terraform environment.
3. Copy the `github_actions_role_arn` output into GitHub repository variables.
4. Confirm ECR repositories exist.
5. Run the `medflow-build-images` workflow.

Current project defaults:

- AWS region: `us-east-2`
- AWS CLI profile: `medflow-dev`
- GitHub repository: `gopalakrishnachennu/medflow`
- Domain: none, use ALB DNS first
- Budget: `$30` hard cap for a short lab window, so dev uses cost-saving defaults and should be destroyed when idle

## Why This Is Enterprise-Style

- Production images are built by trusted runners, not laptops.
- AWS access uses short-lived OIDC credentials.
- Images are scanned before publishing.
- ECR repositories use immutable tags and scan-on-push.
- Deployments are GitOps-controlled.
- Argo CD, not a laptop, applies Kubernetes state.
