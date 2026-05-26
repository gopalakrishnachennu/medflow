# Configure this after creating the remote state bucket and lock table.
# terraform {
#   backend "s3" {
#     bucket         = "medflow-terraform-state-<aws-account-id>"
#     key            = "dev/terraform.tfstate"
#     region         = "us-east-2"
#     dynamodb_table = "medflow-terraform-locks"
#     encrypt        = true
#   }
# }
