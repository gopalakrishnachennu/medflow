# AWS Account Profile

Current MedFlow dev target:

| Setting | Value |
|---|---|
| AWS region | `us-east-2` |
| AWS CLI profile | `medflow-dev` |
| GitHub owner | `gopalakrishnachennu` |
| GitHub repository | `medflow` |
| GitHub URL | `https://github.com/gopalakrishnachennu/medflow.git` |
| Max lab budget | `$30` |
| Expected lab duration | two weeks, up to one month maximum |
| Domain | none |

## Budget Guardrails

The `$30` budget is a hard learning-lab cap for a short-lived environment. It is not a monthly production budget and it does not mean infrastructure should stay running indefinitely.

Dev must stay intentionally small:

- Disable NAT Gateway in dev by default.
- Avoid multi-AZ RDS for dev.
- Use the smallest practical EKS node capacity.
- Prefer short-lived environments and destroy them when not actively learning.
- Avoid CloudFront, WAF, Route 53, and ACM until a domain is available.
- Use ALB DNS for early testing.
- Add AWS Budget alerts before applying infrastructure.
- Tag all resources with `Project=medflow` and `Environment=dev`.

## Cost Operating Rule

For this budget, use this rule:

```text
Create infrastructure only when testing.
Destroy infrastructure when the lab session is finished.
Never leave EKS, RDS, NAT Gateway, or load balancers running without a reason.
```

Before applying infrastructure, create an AWS Budget alert for `$30`.

## AWS CLI Check

Your AWS CLI currently needs a `medflow-dev` profile. Configure it with SSO:

```bash
aws configure sso --profile medflow-dev
```

Then log in:

```bash
aws sso login --profile medflow-dev
```

Then verify access:

```bash
aws sts get-caller-identity --profile medflow-dev
```

Do not share access keys. The account ID and assumed role ARN are enough for setup validation.
