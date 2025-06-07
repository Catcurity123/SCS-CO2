#### Fetch the latest amazon_linux_2 ami
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

# Resource to launch the EC2 instance
resource "aws_instance" "example_web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"

  # Enable metadata for EC2 using IMDSv1 for metadata 
  #### NOT ENCOURAGED ####
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  tags = {
    Name = "latest-amazon-linux-2-public"
  }
}

# Output metadata onto text file using local_file resource
resource "local_file" "instance_metadata" {
  content = <<-EOT
    EC2 INSTANCE METADATA
    ---------------------
    Instance ID: ${aws_instance.example_web.id}
    Instance ARN: ${aws_instance.example_web.arn}
    Instance Type: ${aws_instance.example_web.instance_type}
    AMI Used: ${aws_instance.example_web.ami}
    Public IP: ${aws_instance.example_web.public_ip}
    Private IP: ${aws_instance.example_web.private_ip}
    Availability Zone: ${aws_instance.example_web.availability_zone}
  EOT

  filename = "ec2-metadata.txt"
}