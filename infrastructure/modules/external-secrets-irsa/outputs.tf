output "role_arn" {
  description = "IAM role ARN to annotate on the External Secrets Operator service account."
  value       = aws_iam_role.external_secrets.arn
}
