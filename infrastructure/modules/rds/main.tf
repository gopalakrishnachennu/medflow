resource "aws_db_subnet_group" "default" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.identifier}-subnet-group"
    Environment = var.environment
  }
}

# Generate a random password for the database
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store the password securely in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.environment}/${var.identifier}/credentials"
  description = "Database connection credentials for ${var.identifier}"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.db_password.result
    engine   = var.engine
    dbname   = var.db_name
    host     = aws_db_instance.default.address
    port     = aws_db_instance.default.port
  })
}

resource "aws_db_instance" "default" {
  identifier        = var.identifier
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = var.vpc_security_group_ids

  multi_az               = var.environment == "prod" ? true : false
  publicly_accessible    = false
  storage_encrypted      = true
  skip_final_snapshot    = var.environment == "prod" ? false : true

  # Backup configuration
  backup_retention_period = var.environment == "prod" ? 30 : 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Performance Insights (Enterprise readiness)
  performance_insights_enabled = true

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}
