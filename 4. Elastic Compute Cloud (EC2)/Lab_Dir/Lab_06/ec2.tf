
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
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

locals {
  userdata_IMDSv1 = templatefile("${path.module}/ec2_prep_fold/init_IMDSv1.sh", {
    ssm_cloudwatch_config = aws_ssm_parameter.cw_agent_imdsv1.name
  })
}

locals {
  userdata_docker = templatefile("${path.module}/ec2_prep_fold/juice_shop_2.sh", {
    ssm_cloudwatch_config = aws_ssm_parameter.cw_agent_docker.name
  })
}


resource "aws_ssm_parameter" "cw_agent_docker" {
  description = "Cloudwatch agent config to configure custom log for Docker"
  name        = "/cloudwatch-agent/config-docker"
  type        = "String"
  value       = file("${path.module}/ec2_prep_fold/cw_agent_config.json")
}

resource "aws_ssm_parameter" "cw_agent_imdsv1" {
  description = "Cloudwatch agent config to configure custom log for IMDSv1"
  name        = "/cloudwatch-agent/config-imdsv1"
  type        = "String"
  value       = file("${path.module}/ec2_prep_fold/cw_agent_config_IMDSv1.json")
}


resource "aws_instance" "test_host" {
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.ec2_admin_profile.name
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.default.id]
  key_name               = aws_key_pair.generated_key.key_name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  user_data = local.userdata_IMDSv1
  tags = {
    Name = "IMDSv1-ubuntu2204-admin"
  }
}

resource "aws_instance" "test_host_2" {
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.default.id]
  key_name               = aws_key_pair.generated_key.key_name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  user_data = local.userdata_IMDSv1
  tags = {
    Name = "IMDSv1-ubuntu2204-noinstanceprofile"
  }
}

resource "aws_instance" "test_host_3" {
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.default.id]
  key_name               = aws_key_pair.generated_key.key_name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  user_data = local.userdata_IMDSv1
  tags = {
    Name = "IMDSv1-ubuntu2204-tobetested"
  }
}

resource "aws_instance" "docker_host" {
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.ec2_cloudwatch_profile.name
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.default.id]
  key_name               = aws_key_pair.generated_key.key_name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = local.userdata_docker
  tags = {
    Name = "docker-host"
  }
}



resource "aws_s3_bucket" "shared_bucket" {
  bucket        = "my-unique-bucket-name-123asdasdasdsfs3f"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "shared_bucket_pab" {
  bucket                  = aws_s3_bucket.shared_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}