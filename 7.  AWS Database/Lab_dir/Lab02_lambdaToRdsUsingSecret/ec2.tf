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
resource "aws_key_pair" "generated_key_lab02" {
  key_name   = "bastion-key_lab02"
  public_key = tls_private_key.rsa_key.public_key_openssh
}
# Store the private key pair at local for usage
resource "local_file" "private_key_pem" {
  content         = tls_private_key.rsa_key.private_key_pem
  filename        = "${aws_key_pair.generated_key_lab02.key_name}.pem"
  file_permission = "0400"
}


#ssh-keygen -t rsa -b 4096 -f my-key -C "my-key for AWS"

resource "aws_instance" "lab02_bastion_host" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  # Corrected subnet reference below
  subnet_id = aws_subnet.lab02_public_subnet.id
  # Corrected security group reference below
  vpc_security_group_ids = [aws_security_group.lab02_bastion_sg.id]
  key_name               = aws_key_pair.generated_key_lab02.key_name
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  user_data = file("${path.module}/ec2_prep_fold/init.sh")
  tags = {
    Name = "lalab02-amazon-linux-2-public"
  }
}
