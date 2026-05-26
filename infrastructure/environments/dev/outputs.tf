output "github_actions_role_arn" {
  value       = module.github_oidc.role_arn
  description = "Set this as GitHub repository variable AWS_GITHUB_OIDC_ROLE_ARN."
}

output "ecr_repository_urls" {
  value       = module.ecr.repository_urls
  description = "ECR repositories used by CI image build workflows."
}

output "budget_enabled" {
  value       = module.budget.budget_enabled
  description = "Whether the AWS Budget alert is enabled for dev."
}
