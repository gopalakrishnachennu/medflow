variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "oidc_provider_arn" {
  type        = string
  description = "EKS OIDC provider ARN used for IRSA."
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace where External Secrets Operator runs."
  default     = "external-secrets"
}

variable "service_account_name" {
  type        = string
  description = "Kubernetes service account used by External Secrets Operator."
  default     = "external-secrets"
}

variable "secret_arns" {
  type        = list(string)
  description = "AWS Secrets Manager secret ARNs the operator can read."
}
