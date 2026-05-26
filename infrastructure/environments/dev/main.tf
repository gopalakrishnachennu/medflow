terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source             = "../../modules/vpc"
  project_name       = var.project_name
  cidr_block         = var.vpc_cidr_block
  az_count           = var.az_count
  enable_nat_gateway = var.enable_nat_gateway
}

module "ecr" {
  source               = "../../modules/ecr"
  project_name         = var.project_name
  services             = var.services
  retained_image_count = var.retained_image_count
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  project_name         = var.project_name
  aws_region           = var.aws_region
  github_owner         = var.github_owner
  github_repository    = var.github_repository
  ecr_repository_names = [for service in var.services : "${var.project_name}/${service}"]
}

module "budget" {
  source = "../../modules/budget"

  project_name = var.project_name
  environment  = "dev"
  limit_usd    = var.monthly_budget_limit_usd
  alert_email  = var.budget_alert_email
}
