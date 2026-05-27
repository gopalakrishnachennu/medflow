output "s3_bucket_name" {
  description = "The name of the S3 bucket to store Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "aws_region" {
  description = "The AWS region where the backend resources are provisioned"
  value       = var.aws_region
}
