locals {
  creator_account_id = file("${path.module}/creator_account_id.txt")
}

resource "aws_iam_role" "allow_ec2_assume" {
  name = "EC2AssumeRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "Description" = "Role for EC2 in Accessor Account to allow assuming role"
  }
}

resource "aws_iam_policy" "permission_allow_roleassume" {
  name = "AllowEC2ToAssumeRole"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::${local.creator_account_id}:role/RoleForS3Put"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_sts_policy_attach" {
  role       = aws_iam_role.allow_ec2_assume.name
  policy_arn = aws_iam_policy.permission_allow_roleassume.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instanec_profile"
  role = aws_iam_role.allow_ec2_assume.name
}




data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

## Generate key pair for EC2 useage ##
# Create a key
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Make that key a key pair for aws
resource "aws_key_pair" "generated_key" {
  key_name   = "web-server-key"
  public_key = tls_private_key.rsa_key.public_key_openssh
}
# Store the private key pair at local for usage
resource "local_file" "private_key_pem" {
  content         = tls_private_key.rsa_key.private_key_pem
  filename        = "${aws_key_pair.generated_key.key_name}.pem"
  file_permission = "0400"
}

#ssh-keygen -t rsa -b 4096 -f my-key -C "my-key for AWS"



## Resource to launch the EC2 instance in the public subnet ##
# Create EC2 instance with AMI, instance type, public subnet, SG, key pair, meta data option, user data
resource "aws_instance" "example_web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  # Corrected subnet reference below
  subnet_id = aws_subnet.public1.id
  # Corrected security group reference below
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  key_name               = aws_key_pair.generated_key.key_name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  user_data            = file("${path.module}/ec2_prep_fold/init.sh")
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  tags = {
    Name = "latest-amazon-linux-2-public"
  }
}
