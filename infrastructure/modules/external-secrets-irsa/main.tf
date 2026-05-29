data "aws_iam_openid_connect_provider" "eks" {
  arn = var.oidc_provider_arn
}

locals {
  oidc_provider_url = replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${var.project_name}-${var.environment}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "external_secrets" {
  statement {
    sid = "ReadAllowedSecrets"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = var.secret_arns
  }
}

resource "aws_iam_policy" "external_secrets" {
  name   = "${var.project_name}-${var.environment}-external-secrets"
  policy = data.aws_iam_policy_document.external_secrets.json

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}
