# ============================================================================
# Flantas AWS Assignment - Question 2: EC2 Resume Website Hosting
# Author: Aryan Vishwakarma
# Purpose: Deploy a resume website on EC2 with Nginx and security hardening
# Date: December 2024
# ============================================================================

provider "aws" {
  region = "ap-south-1"
}

# Fetch latest Ubuntu 20.04 LTS AMI from Canonical
# Using official Canonical owner ID to ensure trusted AMI source
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Reference the public subnet created in Question 1
# This demonstrates infrastructure reusability and proper resource dependencies
data "aws_subnet" "public_subnet_1" {
  filter {
    name   = "tag:Name"
    values = ["Aryan_Vishwakarma_PublicSubnet1"]
  }
}

# Security Group for EC2 instance
# Implements defense-in-depth security model
resource "aws_security_group" "resume_sg" {
  name        = "Aryan_Vishwakarma_EC2_SG"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_subnet.public_subnet_1.vpc_id

  # HTTP access - Public website requires world access
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access - Should be restricted to personal IP for production
  # Current setting allows global access for initial setup/demonstration
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Harden - Replace with your IP/32 for production
  }

  # Outbound traffic - Required for package updates and internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Aryan_Vishwakarma_EC2_SG"
  }
}

# EC2 Instance for Resume Website
# t2.micro chosen for Free Tier eligibility and sufficient for static website hosting
resource "aws_instance" "resume_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro" # Free Tier eligible
  subnet_id                   = data.aws_subnet.public_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.resume_sg.id]
  associate_public_ip_address = true # Required for internet access

  # Automated setup via user-data script
  # Script installs Nginx, configures website, and applies security hardening
  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "Aryan_Vishwakarma_ResumeServer"
  }
}

# Output the public IP for easy access to the website
output "public_ip" {
  description = "Public IP address of the resume server"
  value       = aws_instance.resume_server.public_ip
}
