##################################################################################
# RESOURCES
##################################################################################

resource "aws_launch_configuration" "app_server_lc" {
  lifecycle {
    create_before_destroy = true
  }

  name_prefix   = "${terraform.workspace}-ddt-lc-"
  image_id      = "${data.aws_ami.aws_linux.id}"
  instance_type = "t2.micro"

  security_groups = [
    "${aws_security_group.app_server_http_inbound_sg.id}",
    "${aws_security_group.app_server_ssh_inbound_sg.id}",
    "${aws_security_group.app_server_outbound_sg.id}",
  ]

  user_data                   = "${file("./templates/userdata-app.sh")}"
  key_name                    = "${var.key_name}"
}

resource "aws_elb" "app_server_elb" {
  name    = "ddt-app-server-elb"
  subnets = ["${data.terraform_remote_state.networking.private_subnets}"]
  internal      = "true"

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/"
    interval            = 10
  }

  security_groups = ["${aws_security_group.app_server_http_inbound_sg.id}"]

  tags = "${local.common_tags}"
}

resource "aws_autoscaling_group" "app_server_asg" {
  lifecycle {
    create_before_destroy = true
  }

  vpc_zone_identifier   = ["${data.terraform_remote_state.networking.private_subnets}"]
  name                  = "ddt_app_server_asg"
  max_size              = "1"
  min_size              = "1"
  wait_for_elb_capacity = false
  force_delete          = true
  launch_configuration  = "${aws_launch_configuration.app_server_lc.id}"
  load_balancers        = ["${aws_elb.app_server_elb.name}"]

  tags = ["${
    list(
      map("key", "Name", "value", "ddt_app_server_asg", "propagate_at_launch", true),
      map("key", "environment", "value", "development", "propagate_at_launch", true)
    )
  }"]
}

#
# Scale Up Policy and Alarm
#
resource "aws_autoscaling_policy" "app_server_scale_up" {
  name                   = "ddt_app_server_asg_scale_up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.app_server_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "app_server_scale_up_alarm" {
  alarm_name                = "ddt-app-server-high-asg-cpu"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  insufficient_data_actions = []

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.app_server_asg.name}"
  }

  alarm_description = "EC2 CPU Utilization"
  alarm_actions     = ["${aws_autoscaling_policy.app_server_scale_up.arn}"]
}

#
# Scale Down Policy and Alarm
#
resource "aws_autoscaling_policy" "app_server_scale_down" {
  name                   = "ddt_app_server_asg_scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 600
  autoscaling_group_name = "${aws_autoscaling_group.app_server_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "app_server_scale_down_alarm" {
  alarm_name                = "ddt-app-server-low-asg-cpu"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "30"
  insufficient_data_actions = []

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.app_server_asg.name}"
  }

  alarm_description = "EC2 CPU Utilization"
  alarm_actions     = ["${aws_autoscaling_policy.app_server_scale_down.arn}"]
}