variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "project_name" {
  type    = string
  default = "medflow"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.40.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "services" {
  type    = list(string)
  default = ["auth-service", "patient-service", "appointment-service", "records-service", "pharmacy-service", "billing-service", "notification-service", "frontend"]
}

variable "retained_image_count" {
  type    = number
  default = 30
}

variable "monthly_budget_limit_usd" {
  type        = number
  description = "Hard learning-lab budget guardrail for the dev account."
  default     = 30
}

variable "budget_alert_email" {
  type        = string
  description = "Email address that receives AWS Budget alerts."
  default     = ""
}

variable "github_owner" {
  type        = string
  description = "GitHub organization or username that owns the repository."
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name."
}
