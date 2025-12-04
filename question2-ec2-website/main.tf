provider "aws" {
  region = "ap-south-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "aws_subnet" "public_subnet_1" {
  filter {
    name   = "tag:Name"
    values = ["Aryan_Vishwakarma_PublicSubnet1"]
  }
}

# Security Group
resource "aws_security_group" "resume_sg" {
  name        = "Aryan_Vishwakarma_EC2_SG"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_subnet.public_subnet_1.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict to your IP for production
  }

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

# EC2 Instance
resource "aws_instance" "resume_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.public_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.resume_sg.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "Aryan_Vishwakarma_ResumeServer"
  }
}

output "public_ip" {
  value = aws_instance.resume_server.public_ip
}
