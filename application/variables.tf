#Remove State variables
variable "network_remote_state_key" {
  default = "application.state"
}

variable "network_remote_state_bucket" {
  default = "your application bucket"
}

variable "aws_profile" {}

#Web front end variables
variable "key_name" {
  default = "yetanotherkey"
}

variable "ip_range" {
  default = "0.0.0.0/0"
}