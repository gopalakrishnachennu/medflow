terraform {
  backend "s3" {
    bucket         = "medflow-terraform-state-1fd2a736"
    key            = "dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "medflow-terraform-locks"
    encrypt        = true
  }
}
