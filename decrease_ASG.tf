resource "aws_autoscaling_group" "lc_server_asg" {
  count = 12

  desired_capacity     = 1  # Decrease capacity after QA confirmation
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier  = ["subnet-xxxxxxxx"]  # Your subnet
  launch_template {
    launch_template_id = aws_launch_template.lc_server_template[count.index].id
    version            = "$Latest"
  }
}
