output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.default.address
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.default.endpoint
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.default.db_name
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.default.port
}

output "secret_arn" {
  description = "The ARN of the Secrets Manager secret containing the database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
