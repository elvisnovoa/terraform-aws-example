##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  profile = "${var.aws_profile}"
  region  = "us-east-1"
}

##################################################################################
# RESOURCES
##################################################################################

resource "aws_launch_configuration" "web_lc" {
  lifecycle {
    create_before_destroy = true
  }

  name_prefix   = "${terraform.workspace}-ddt-lc-"
  image_id      = "${data.aws_ami.aws_linux.id}"
  instance_type = "t2.micro"

  security_groups = [
    "${aws_security_group.web_http_inbound_sg.id}",
    "${aws_security_group.web_ssh_inbound_sg.id}",
    "${aws_security_group.web_outbound_sg.id}",
  ]

  user_data                   = "${data.template_file.user_data_web.rendered}"
  key_name                    = "${var.key_name}"
  associate_public_ip_address = true
}

resource "aws_elb" "web_elb" {
  name    = "ddt-web-elb"
  subnets = ["${data.terraform_remote_state.networking.public_subnets}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }

  security_groups = ["${aws_security_group.web_http_inbound_sg.id}"]

  tags = "${local.common_tags}"
}

resource "aws_autoscaling_group" "web_asg" {
  lifecycle {
    create_before_destroy = true
  }

  vpc_zone_identifier   = ["${data.terraform_remote_state.networking.public_subnets}"]
  name                  = "ddt_web_asg"
  max_size              = "1"
  min_size              = "1"
  wait_for_elb_capacity = false
  force_delete          = true
  launch_configuration  = "${aws_launch_configuration.web_lc.id}"
  load_balancers        = ["${aws_elb.web_elb.name}"]

  tags = ["${
    list(
      map("key", "Name", "value", "ddt_web_asg", "propagate_at_launch", true),
      map("key", "environment", "value", "development", "propagate_at_launch", true)
    )
  }"]
}

#
# Scale Up Policy and Alarm
#
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "ddt_asg_scale_up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.web_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name                = "ddt-high-asg-cpu"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  insufficient_data_actions = []

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.web_asg.name}"
  }

  alarm_description = "EC2 CPU Utilization"
  alarm_actions     = ["${aws_autoscaling_policy.scale_up.arn}"]
}

#
# Scale Down Policy and Alarm
#
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "ddt_asg_scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 600
  autoscaling_group_name = "${aws_autoscaling_group.web_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name                = "ddt-low-asg-cpu"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "30"
  insufficient_data_actions = []

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.web_asg.name}"
  }

  alarm_description = "EC2 CPU Utilization"
  alarm_actions     = ["${aws_autoscaling_policy.scale_down.arn}"]
}

resource "aws_instance" "bastion" {
  ami                         = "${data.aws_ami.aws_linux.id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${element(data.terraform_remote_state.networking.public_subnets,0)}"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.bastion_ssh_sg.id}"]
  key_name                    = "${var.key_name}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "ddt_bastion_host",
    )
  )}"
}

resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc      = true
}