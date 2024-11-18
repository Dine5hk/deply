resource "aws_security_group" "app_sg" {
  name_prefix = "app-sg-"
}

resource "aws_autoscaling_group" "app_asg" {
  desired_capacity     = 1
  min_size             = 1
  max_size             = 5
  vpc_zone_identifier  = ["subnet-xxxxxx"]  # Specify your subnet IDs
  launch_template {
    launch_template_name = aws_launch_template.app_launch_template.name
    version              = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
  health_check_interval     = 30
  wait_for_capacity_timeout = 0
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-xxxxxxxx"  # Specify your VPC ID
}

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.app_sg.id]
  subnets            = ["subnet-xxxxxx"]  # Specify your subnet IDs

  enable_deletion_protection = false
}
