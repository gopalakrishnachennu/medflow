aws_region         = "us-east-2"
project_name       = "medflow"
vpc_cidr_block     = "10.40.0.0/16"
az_count           = 2
enable_nat_gateway = false

github_owner      = "gopalakrishnachennu"
github_repository = "medflow"

monthly_budget_limit_usd = 30

# Set this before applying the AWS budget resource.
budget_alert_email = ""
