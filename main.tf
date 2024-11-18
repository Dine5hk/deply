# Example of EC2 instance for one server (repeat for 12 instances)
resource "aws_instance" "lc_server" {
  count         = 12
  ami           = "ami-xxxxxxxxxxxxxxx"  # Base AMI (modify for each server)
  instance_type = "t2.micro"  # Modify to your required instance type
  key_name      = "your-key-pair"  # SSH key for access to servers
  subnet_id     = "subnet-xxxxxxxx"  # Your VPC subnet ID
  security_groups = ["sg-xxxxxxxx"]  # Security group ID for the instances
  tags = {
    Name = "LC-Server-${count.index + 1}"
  }

  # Optional: Use user_data for setup (installing dependencies, etc.)
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y
                sudo apt-get install -y nginx
                EOF
}

# Create AMI after backup and configuration on the LC server
resource "aws_ami" "lc_server_ami" {
  count               = 12
  name                = "lc-server-ami-${count.index + 1}-${timestamp()}"
  description         = "Custom AMI for LC server ${count.index + 1}"
  source_instance_id  = aws_instance.lc_server[count.index].id

  lifecycle {
    create_before_destroy = true
  }
}

# Create Launch Template (for each server)
resource "aws_launch_template" "lc_server_template" {
  count = 12

  name = "lc-server-template-${count.index + 1}"

  launch_template_data {
    image_id      = aws_ami.lc_server_ami[count.index].id
    instance_type = "t2.micro"  # Modify based on your requirements
    key_name      = "your-key-pair"
    security_groups = ["sg-xxxxxxxx"]  # Security group for the new launch template
    user_data     = <<-EOF
                    #!/bin/bash
                    sudo apt-get update -y
                    sudo apt-get install -y nginx
                    EOF
  }
}

# Automate Launch Template version creation for each server
resource "null_resource" "create_launch_template_version" {
  count = 12
  depends_on = [aws_ami.lc_server_ami]

  provisioner "local-exec" {
    command = <<-EOT
      /usr/bin/aws ec2 create-launch-template-version \
        --launch-template-id lt-08a8b340bfe32962b \
        --version-description "10052024@V1.12.13.3" \
        --source-version 2 \
        --launch-template-data '{"ImageId":"${aws_ami.lc_server_ami[count.index].id}"}' \
        --region ap-south-1
    EOT
  }
}

# Auto Scaling Group (ASG) configuration for each server
resource "aws_autoscaling_group" "lc_server_asg" {
  count = 12

  desired_capacity     = 1
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier  = ["subnet-xxxxxxxx"]  # Your subnet
  launch_template {
    launch_template_id = aws_launch_template.lc_server_template[count.index].id
    version            = "$Latest"
  }
}

# Target Group for each server
resource "aws_lb_target_group" "lc_server_target_group" {
  count = 12

  name     = "lc-server-tg-${count.index + 1}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-xxxxxxxx"  # Your VPC ID
}

# Health check for the Target Group
resource "aws_lb_target_group_attachment" "lc_server_tg_attachment" {
  count = 12

  target_group_arn = aws_lb_target_group.lc_server_target_group[count.index].arn
  target_id        = aws_instance.lc_server[count.index].id
  port             = 80
}






