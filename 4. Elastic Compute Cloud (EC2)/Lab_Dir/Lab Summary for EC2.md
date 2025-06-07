#### A. Create EC2 with full option and output useful information

###### Requirement
(+) Create EC2 with minimal setting
(+) The output of Terraform should have information like EC2's public IP, EC2's AMI. EC2's region

###### Steps
(1) Fetch ami using data block

```
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
```

(2) Deploy aws_instance block
```
resource "aws_instance" "example_web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  #key_name = aws_key_pair.ec2_keyssh.key_name
  tags = {
    Name = "latest-amazon-linux-2-public"
  }
}
```


#### B. Create EC2 with IMDSv1 and output metadata onto a local text file
(+) Enabled metadata on the current EC2
(+) Output the metadata onto local textfile 

(1) Enable metadata on the current EC2
```
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
```

(2) Output metadata onto local text file

```
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
```

#### C. Create EC2 with IMDSv2 and output metadata onto a web page view
(+) Enable IMDVs2 for EC2
(+) Create an init script for ec2 
(+) Create VPC with public subnet for EC2 
(+) Create key pair to interact and configure EC2 
(+) Output necessary information

(1) Enable IMDVs2 through metadata in EC2
```
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
```

(2) Create init script for EC2's user data 
```
#!/bin/bash
#
# This script is executed by the EC2 instance upon launch.
# It installs NGINX and creates a web page to display instance metadata.
#

# Update packages and install NGINX for Amazon Linux 2
yum update -y
amazon-linux-extras install nginx1 -y
systemctl start nginx
systemctl enable nginx

# Get a security token for IMDSv2 (valid for 6 hours)
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

# Create the HTML file for the web server's root
cat <<EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>EC2 Instance Metadata</title>
</head>
<body>
    <div class="container">
        <h1>EC2 Instance Metadata (via IMDSv2)</h1>
        <p><strong>Instance ID:</strong> $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)</p>
        <p><strong>Instance Type:</strong> $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)</p>
        <p><strong>Availability Zone:</strong> $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
        <p><strong>Public IPv4:</strong> $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4)</p>
        <p><strong>AMI ID:</strong> $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/ami-id)</p>
    </div>
</body>
</html>
EOF
```

(3) Create VPC for EC2 to be accessible through the internet. For this to be done, we need the following configuration:
    + We need a VPC
    + We need a public subnet
    + For the public subnet to work, we need to implement an internet gateway. And we also need to make a route table to direct the public subnet to the internet gateway
    + We need to associate the route table with the public subnet
    + We need a security group stating the ingress and egress data flow for the subnet 

```
# 1. Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# 2. Create an Internet Gateway to allow communication with the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# 3. Create a Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true         # Automatically assign a public IP to instances
  availability_zone       = "us-east-1a" # Change to an AZ in your selected region

  tags = {
    Name = "public-subnet"
  }
}

# 4. Create a Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # 5. Create a route that directs internet-bound traffic to the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# 6. Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a Security Group to allow SSH and all outbound traffic
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: For production, restrict this to your IP address.
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: For production, restrict this to your IP address.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh-sg"
  }
}
```
(4) Create a key pair for ssh to EC2 
```
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
```

(5) Output necessary information
```
output "instance_public_url" {
  description = "URL to view the instance metadata web page."
  value       = "http://${aws_instance.example_web.public_ip}"
}

output "ssh_command" {
  description = "Command to SSH into the instance."
  value       = "ssh -i ${local_file.private_key_pem.filename} ec2-user@${aws_instance.example_web.public_ip}"
}
```

#### D. Create EC2 with IMDSv2 and output the metadata html file onto S3 bucket <-> S3 must be through assumerole