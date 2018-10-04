##################################################################################
# BACKENDS
##################################################################################
terraform {
  backend "s3" {
    key            = "networking.state"
    region         = "us-east-1"
    profile        = "networking"
    dynamodb_table = "ddt-tfstatelock"
  }
}
