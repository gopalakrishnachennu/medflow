variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "github_owner" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "ecr_repository_names" {
  type = list(string)
}

variable "github_oidc_thumbprint" {
  type        = string
  description = "GitHub Actions OIDC root CA thumbprint."
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

