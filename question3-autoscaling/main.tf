# ============================================================================
# Flantas AWS Assignment - Question 3: Auto Scaling & Load Balancing
# Author: Aryan Vishwakarma
# Purpose: Implement auto-scaling infrastructure with ALB for high availability
# Date: December 2024
# Architecture: ALB → ASG (Private Subnets) with CPU-based scaling policies
# ============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-south-1"
}

############################
# Data Sources: Reuse VPC Infrastructure from Question 1
############################
# This demonstrates proper resource dependency management
# and infrastructure reusability across different components

# Public subnets for Application Load Balancer (internet-facing)
data "aws_subnet" "public_1" {
  filter {
    name   = "tag:Name"
    values = ["Aryan_Vishwakarma_PublicSubnet1"]
  }
}

data "aws_subnet" "public_2" {
  filter {
    name   = "tag:Name"
    values = ["Aryan_Vishwakarma_PublicSubnet2"]
  }
}

# Private subnets for Auto Scaling Group instances (enhanced security)
data "aws_subnet" "private_1" {
  filter {
    name   = "tag:Name"
    values = ["Aryan_Vishwakarma_PrivateSubnet1"]
  }
}

data "aws_subnet" "private_2" {
  filter {
    name   = "tag:Name"
    values = ["Aryan_Vishwakarma_PrivateSubnet2"]
  }
}

############################
# AMI for EC2 (Ubuntu)
############################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

############################
# Security Groups
############################

# ALB Security Group – allow HTTP from internet
resource "aws_security_group" "alb_sg" {
  name        = "aryan-vishwakarma-alb-sg"
  description = "ALB security group"
  vpc_id      = data.aws_subnet.public_1.vpc_id

  tags = {
    Name = "Aryan_Vishwakarma_ALB_SG"
  }
}

# Allow inbound HTTP from anywhere to ALB
resource "aws_security_group_rule" "alb_http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

# Allow ALB to talk out
resource "aws_security_group_rule" "alb_all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

# App Security Group – for EC2 instances in private subnets
resource "aws_security_group" "app_sg" {
  name        = "aryan-vishwakarma-app-sg"
  description = "App instances behind ALB"
  vpc_id      = data.aws_subnet.private_1.vpc_id

  tags = {
    Name = "Aryan_Vishwakarma_App_SG"
  }
}

# Allow HTTP only from ALB SG
resource "aws_security_group_rule" "app_http_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

# Allow instances to go out (to internet via NAT GW)
resource "aws_security_group_rule" "app_all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_sg.id
}

############################
# Target Group
############################

resource "aws_lb_target_group" "app_tg" {
  name     = "aryan-vishwakarma-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_subnet.private_1.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200,301,302"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "Aryan_Vishwakarma_TargetGroup"
  }
}

############################
# Application Load Balancer
############################

resource "aws_lb" "app_alb" {
  name               = "aryan-vishwakarma-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [data.aws_subnet.public_1.id, data.aws_subnet.public_2.id]

  tags = {
    Name = "Aryan_Vishwakarma_ALB"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

############################
# Launch Template for ASG instances
############################

resource "aws_launch_template" "app_lt" {
  name_prefix   = "aryan-vishwakarma-app-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = base64encode(file("${path.module}/user_data.sh"))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Aryan_Vishwakarma_AppInstance"
    }
  }

  tags = {
    Name = "Aryan_Vishwakarma_LaunchTemplate"
  }
}

############################
# Auto Scaling Group
############################

resource "aws_autoscaling_group" "app_asg" {
  name                      = "aryan-vishwakarma-asg"
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  health_check_type         = "ELB"
  health_check_grace_period = 300

  vpc_zone_identifier = [
    data.aws_subnet.private_1.id,
    data.aws_subnet.private_2.id
  ]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  tag {
    key                 = "Name"
    value               = "Aryan_Vishwakarma_AppInstance"
    propagate_at_launch = true
  }

  depends_on = [aws_lb_listener.http_listener]
}

############################
# Outputs
############################

output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}
