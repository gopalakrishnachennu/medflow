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

module "eks" {
  source       = "../../modules/eks"
  cluster_name = "${var.project_name}-dev"
  environment  = "dev"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-sg-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow PostgreSQL traffic from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = {
    Name    = "${var.project_name}-rds-sg"
    Project = var.project_name
  }
}

module "rds" {
  source                 = "../../modules/rds"
  identifier             = "${var.project_name}-dev-db"
  environment            = "dev"
  db_name                = "medflow"
  username               = "medflow_admin"
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds.id]
}

resource "aws_secretsmanager_secret" "app_runtime" {
  name        = "/${var.project_name}/dev/app"
  description = "Runtime application secrets for MedFlow dev. Values are managed outside Git."

  tags = {
    Project     = var.project_name
    Environment = "dev"
  }
}

module "external_secrets_irsa" {
  source = "../../modules/external-secrets-irsa"

  project_name      = var.project_name
  environment       = "dev"
  oidc_provider_arn = module.eks.oidc_provider_arn
  secret_arns = [
    module.rds.secret_arn,
    aws_secretsmanager_secret.app_runtime.arn
  ]
}
