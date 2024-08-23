terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# Key pair
resource "aws_key_pair" "lab_key" {
  key_name = "lab_key"
  public_key = file("${path.module}/lab_key.pub")
}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "a4l-vpc"
  cidr = "10.16.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.16.48.0/20", "10.16.112.0/20", "10.16.176.0/20"]

  enable_dns_support   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    Name = "a4l-public"
  }

  tags = {
    Name = "a4l-vpc"
  }
}

# Security Group Module 
resource "aws_security_group" "Web_SG" {
  name        = "a4l-security-group"
  description = "Allow SSH and HTTP inbound and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port   = 80 
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web_SG"
  }
}




# EC2 Instances
module "ec2_instance_a" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  associate_public_ip_address = true
  name           = "a4l-hosting-a"
  ami            = "ami-04a81a99f5ec58529"
  key_name               = "lab_key"
  instance_type  = "t2.micro"
  user_data = "${file("ec2_userdata_A.sh")}"
  subnet_id      = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.Web_SG.id]

  tags = {
    Name = "a4l-ec2-instance-a"
  }
}

module "ec2_instance_b" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  associate_public_ip_address = true
  name           = "a4l-hosting-b"
  ami            = "ami-04a81a99f5ec58529"
  key_name               = "lab_key"
  instance_type  = "t2.micro"
  user_data = "${file("ec2_userdata_B.sh")}"
  subnet_id      = module.vpc.public_subnets[1]
  vpc_security_group_ids = [aws_security_group.Web_SG.id]

  tags = {
    Name = "a4l-ec2-instance-b"
  }
}
