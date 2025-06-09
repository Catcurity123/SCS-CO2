# --- 1. Core VPC ---
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# --- 2. Public Subnet Components (for Bastion Host) ---

# Internet Gateway for the VPC
resource "aws_internet_gateway" "main_vpc_gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-vpc-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

# Route Table for the Public Subnet to route traffic to the Internet Gateway
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_vpc_gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the Public Route Table with the Public Subnet
resource "aws_route_table_association" "public_rtb_association" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rtb.id
}


# --- 3. Private Subnet Components (for Application Servers) ---

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main_vpc.id # CORRECTED: Was aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"

  tags = {
    Name = "private-subnet-1"
  }
}

# Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat-gateway-eip"
  }
}

# NAT Gateway, placed in the PUBLIC subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id # CORRECTED: Was aws_subnet.public.id

  tags = {
    Name = "main-nat-gateway"
  }

  # Ensure the Internet Gateway is created before the NAT Gateway
  depends_on = [aws_internet_gateway.main_vpc_gw] # CORRECTED: Was aws_internet_gateway.gw
}

# Route Table for the Private Subnet to route traffic to the NAT Gateway
resource "aws_route_table" "private_rtb" { # CORRECTED: Renamed from "private" to avoid conflict
  vpc_id = aws_vpc.main_vpc.id           # CORRECTED: Was aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Associate the Private Route Table with the Private Subnet
resource "aws_route_table_association" "private_rtb_association" { # CORRECTED: Renamed from "private"
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rtb.id # CORRECTED: Updated to use new route table name
}


# --- 4. Security Groups ---

# Security Group for the Bastion Host (in the Public Subnet)
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH inbound traffic to Bastion Host"
  vpc_id      = aws_vpc.main_vpc.id # CORRECTED: Was aws_vpc.main.id

  ingress {
    description = "SSH from the internet"
    from_port   = 22
    to_port     = 22
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
    Name = "bastion-sg"
  }
}

# Security Group for the instances in the Private Subnet
resource "aws_security_group" "private_sg" {
  name        = "private-app-sg"
  description = "Allow traffic from within the VPC"
  vpc_id      = aws_vpc.main_vpc.id # CORRECTED: Was aws_vpc.main.id

  # Allow SSH access ONLY from the Bastion Host's security group
  ingress {
    description     = "SSH from Bastion Host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Allow all outbound traffic so instances can reach the internet via the NAT Gateway for updates etc.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg"
  }
}

