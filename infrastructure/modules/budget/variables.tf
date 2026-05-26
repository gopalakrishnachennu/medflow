variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "limit_usd" {
  type = number
}

variable "alert_email" {
  type      = string
  sensitive = true
}

