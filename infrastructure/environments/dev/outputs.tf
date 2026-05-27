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
  sensitive   = true
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "The name of the EKS cluster."
}

output "rds_endpoint" {
  value       = module.rds.db_instance_endpoint
  description = "The endpoint for the RDS instance."
}

output "rds_secret_arn" {
  value       = module.rds.secret_arn
  description = "The ARN of the Secrets Manager secret containing RDS credentials."
}
