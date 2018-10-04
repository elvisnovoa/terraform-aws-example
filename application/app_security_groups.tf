##################################################################################
# RESOURCES
##################################################################################
resource "aws_security_group" "app_server_http_inbound_sg" {
  name        = "app_server_http_inbound"
  description = "Allow HTTP from Anywhere"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${data.terraform_remote_state.networking.vpc_id}"

  tags {
    Name = "terraform_app_server_http_inbound"
  }
}

resource "aws_security_group" "app_server_ssh_inbound_sg" {
  name        = "app_server_ssh_inbound"
  description = "Allow SSH from certain ranges"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ip_range}"]
  }

  vpc_id = "${data.terraform_remote_state.networking.vpc_id}"

  tags {
    Name = "terraform_app_server_ssh_inbound"
  }
}

resource "aws_security_group" "app_server_outbound_sg" {
  name        = "app_server_outbound"
  description = "Allow outbound connections"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${data.terraform_remote_state.networking.vpc_id}"

  tags {
    Name = "terraform_app_server_outbound"
  }
}
