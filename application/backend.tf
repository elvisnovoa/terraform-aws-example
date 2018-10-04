##################################################################################
# BACKENDS
##################################################################################
terraform {
  backend "s3" {
    key            = "application.state"
    region         = "us-east-1"
    profile        = "developers"
    dynamodb_table = "ddt-tfstatelock"
  }
}
