variable "project_name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "az_count" {
  type    = number
  default = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "At least two availability zones are required for enterprise-style high availability."
  }
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}
