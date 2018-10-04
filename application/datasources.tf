locals {
  common_tags = {
    #environment      = "${data.external.configuration.result.environment}"
    environment      = "development"
  }

  workspace_key = "env:/${terraform.workspace}/${var.network_remote_state_key}"
}

data "terraform_remote_state" "networking" {
  backend = "s3"

  config {
    key     = "${terraform.workspace == "default" ? var.network_remote_state_key : local.workspace_key}"
    bucket  = "${var.network_remote_state_bucket}"
    region  = "us-east-1"
    profile = "${var.aws_profile}"
  }
}

# amazon linux ami
data "aws_ami" "aws_linux" {
  most_recent = true
  owners     = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-20*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "external" "configuration" {
  program = ["bash", "../scripts/myscript.sh"]

  # Optional request headers
  # query = {  }
}

data "template_file" "user_data_web" {
  template = "${file("./templates/userdata-web.sh")}"

  vars = {
    app_lb = "${aws_elb.app_server_elb.dns_name}"
  }
}
