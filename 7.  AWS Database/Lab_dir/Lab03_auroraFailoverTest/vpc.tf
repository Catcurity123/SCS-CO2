# --- 1. VPC ---
resource "aws_vpc" "lab03_vpc" {
  cidr_block         = "10.10.0.0/16"
  enable_dns_support = true

  tags = {
    Name = "lab03-vpc"
  }
}

# --- 2.  Public Subnets ---
resource "aws_subnet" "lab03_public_subnet" {
  vpc_id                  = aws_vpc.lab03_vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "lab03-public-subnet"
  }
}

## --- 2.1 Public Networking Assets ---
resource "aws_internet_gateway" "lab03_internet_gateway" {
  vpc_id = aws_vpc.lab03_vpc.id

  tags = {
    Name = "lab03-IGW"
  }
}

resource "aws_route_table" "lab03_public_rtb" {
  vpc_id = aws_vpc.lab03_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab03_internet_gateway.id
  }

  tags = {
    Name = "lab03-public-routeTable"
  }
}

resource "aws_route_table_association" "lab03_public_rtb_association" {
  subnet_id      = aws_subnet.lab03_public_subnet.id
  route_table_id = aws_route_table.lab03_public_rtb.id
}

# --- 3. Private Subnets ----
resource "aws_subnet" "lab03_private_subnet" {
  vpc_id            = aws_vpc.lab03_vpc.id
  cidr_block        = "10.10.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "lab03-private-subnet"
  }
}

resource "aws_subnet" "lab03_private_subnet_2" {
  vpc_id            = aws_vpc.lab03_vpc.id
  cidr_block        = "10.10.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "lab03-private-subnet-2"
  }
}

## --- 3.1 Private Subnet Networking Assets ---
resource "aws_eip" "lab03_nat_ip" {
  domain = "vpc"

  tags = {
    Name = "nat-gw-eip"
  }
}

resource "aws_nat_gateway" "lab03_natgw" {
  allocation_id = aws_eip.lab03_nat_ip.id
  subnet_id     = aws_subnet.lab03_public_subnet.id

  tags = {
    Name = "lab03-nat-gw"
  }

  depends_on = [aws_internet_gateway.lab03_internet_gateway]
}

resource "aws_route_table" "lab03_private_rtb" {
  vpc_id = aws_vpc.lab03_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lab03_natgw.id
  }

  tags = {
    Name = "lab03-private-rtb"
  }
}

resource "aws_route_table_association" "lab03_private_rtb_association" {
  subnet_id      = aws_subnet.lab03_private_subnet.id
  route_table_id = aws_route_table.lab03_private_rtb.id
}

resource "aws_route_table_association" "lab03_private_rtb_association_2" {
  subnet_id      = aws_subnet.lab03_private_subnet_2.id
  route_table_id = aws_route_table.lab03_private_rtb.id
}


# --- 4. Security Group ---
resource "aws_security_group" "lab03_db_sg" {
  name        = "private-lab03-db-sg"
  description = "Allow traffic from and to db"
  vpc_id      = aws_vpc.lab03_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.lab03_lambda_sg.id]
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lab03_bastion_sg.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.lab03_lambda_sg.id]
  }

  tags = {
    Name = "private-db-sg"
  }
}

resource "aws_security_group" "lab03_lambda_sg" {
  name        = "private-lab03-lambda-sg"
  description = "Allow traffic from and to lambda"
  vpc_id      = aws_vpc.lab03_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-lambda-sg"
  }
}

resource "aws_security_group" "lab03_bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH inbound traffic to Bastion Host"
  vpc_id      = aws_vpc.lab03_vpc.id

  ingress {
    description = "SSH from the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
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