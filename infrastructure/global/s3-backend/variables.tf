variable "aws_region" {
  description = "AWS region for the remote backend"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "The name of the project to prefix resources"
  type        = string
  default     = "medflow"
}
