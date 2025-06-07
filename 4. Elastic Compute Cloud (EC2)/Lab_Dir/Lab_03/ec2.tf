## Data source to get the latest Amazon Linux 2 AMI ##
# https://amilookup.com/
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





## Resource to launch the EC2 instance in the public subnet ##
# Create EC2 instance with AMI, instance type, public subnet, SG, key pair, meta data option, user data
resource "aws_instance" "example_web" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name               = aws_key_pair.generated_key.key_name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  user_data = file("${path.module}/ec2_prep_fold/init.sh")
  tags = {
    Name = "latest-amazon-linux-2-public"
  }
}
