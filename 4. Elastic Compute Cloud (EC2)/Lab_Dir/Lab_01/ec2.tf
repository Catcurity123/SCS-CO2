
# Data source to get the latest Amazon Linux 2 AMI
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

# Resource to launch the EC2 instance in the public subnet
resource "aws_instance" "example_web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  tags = {
    Name = "latest-amazon-linux-2-public"
  }
}
