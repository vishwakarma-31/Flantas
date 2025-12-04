# ============================================================================
# Flantas AWS Assignment - Question 1: Networking & Subnetting
# Author: Aryan Vishwakarma
# Purpose: Create a complete VPC infrastructure with public/private subnets
# Date: December 2024
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
  region = "ap-south-1" # Mumbai region - chosen for low latency to India
}

############################
# VPC Configuration
############################
# Creating a VPC with /16 CIDR block to accommodate multiple subnets
# DNS support enabled for EC2 instances to resolve public DNS names

resource "aws_vpc" "aryan_vpc" {
  cidr_block           = "10.0.0.0/16" # Provides 65,536 IP addresses
  enable_dns_support   = true           # Required for DNS resolution
  enable_dns_hostnames = true           # Allows public DNS hostnames

  tags = {
    Name = "Aryan_Vishwakarma_VPC"
  }
}

############################
# Subnets - Multi-AZ Configuration
############################
# Distributing subnets across 2 availability zones for high availability
# This ensures the infrastructure remains operational even if one AZ fails

# Query available AZs in ap-south-1 region
data "aws_availability_zones" "available" {
  state = "available"
}

# Public Subnet 1
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.aryan_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Aryan_Vishwakarma_PublicSubnet1"
  }
}

# Public Subnet 2
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.aryan_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "Aryan_Vishwakarma_PublicSubnet2"
  }
}

# Private Subnet 1
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.aryan_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Aryan_Vishwakarma_PrivateSubnet1"
  }
}

# Private Subnet 2
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.aryan_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Aryan_Vishwakarma_PrivateSubnet2"
  }
}

############################
# Internet Gateway
############################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.aryan_vpc.id

  tags = {
    Name = "Aryan_Vishwakarma_IGW"
  }
}

############################
# Public Route Table
############################

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.aryan_vpc.id

  tags = {
    Name = "Aryan_Vishwakarma_PublicRouteTable"
  }
}

# Default route: Internet via IGW
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate public subnets with public RT
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

############################
# NAT Gateway (for Private Subnets)
############################

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "Aryan_Vishwakarma_NAT_EIP"
  }
}

# NAT Gateway in Public Subnet 1
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "Aryan_Vishwakarma_NATGateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

############################
# Private Route Table
############################

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.aryan_vpc.id

  tags = {
    Name = "Aryan_Vishwakarma_PrivateRouteTable"
  }
}

# Default route for private subnets: go through NAT GW
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# Associate private subnets with private RT
resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}
