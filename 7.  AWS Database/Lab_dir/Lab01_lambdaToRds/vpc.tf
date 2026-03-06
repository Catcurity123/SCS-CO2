# --- 1. VPC ---
resource "aws_vpc" "test_vpc" {
  cidr_block         = "10.1.0.0/16"
  enable_dns_support = true

  tags = {
    Name = "test-vpc"
  }
}

# --- 2.  Public Subnets ---
resource "aws_subnet" "test_public_subnet" {
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "test-public-subnet"
  }
}

## --- 2.1 Public Networking Assets ---
resource "aws_internet_gateway" "test_internet_gateway" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "test-IGW"
  }
}

resource "aws_route_table" "test_public_rtb" {
  vpc_id = aws_vpc.test_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_internet_gateway.id
  }

  tags = {
    Name = "test-public-routeTable"
  }
}

resource "aws_route_table_association" "test_public_rtb_association" {
  subnet_id      = aws_subnet.test_public_subnet.id
  route_table_id = aws_route_table.test_public_rtb.id
}

# --- 3. Private Subnets ----
resource "aws_subnet" "test_private_subnet" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.1.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "test-private-subnet"
  }
}

resource "aws_subnet" "test_private_subnet_2" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.1.12.0/24"
  availability_zone = "us-east-1b" # ← different AZ from your first (us-east-1a)

  tags = {
    Name = "test-private-subnet-2"
  }
}

## --- 3.1 Private Subnet Networking Assets ---
resource "aws_eip" "test_nat_ip" {
  domain = "vpc"

  tags = {
    Name = "nat-gw-eip"
  }
}

resource "aws_nat_gateway" "test_natgw" {
  allocation_id = aws_eip.test_nat_ip.id
  subnet_id     = aws_subnet.test_public_subnet.id

  tags = {
    Name = "test-nat-gw"
  }

  depends_on = [aws_internet_gateway.test_internet_gateway]
}

resource "aws_route_table" "test_private_rtb" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.test_natgw.id
  }

  tags = {
    Name = "test-private-rtb"
  }
}

resource "aws_route_table_association" "test_private_rtb_association" {
  subnet_id      = aws_subnet.test_private_subnet.id
  route_table_id = aws_route_table.test_private_rtb.id
}

resource "aws_route_table_association" "test_private_rtb_association_2" {
  subnet_id      = aws_subnet.test_private_subnet_2.id
  route_table_id = aws_route_table.test_private_rtb.id
}


# --- 4. Security Group ---
resource "aws_security_group" "test_db_sg" {
  name        = "private-test-db-sg"
  description = "Allow traffic from and to db"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.test_lambda_sg.id]
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.test_bastion_sg.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.test_lambda_sg.id]
  }

  tags = {
    Name = "private-db-sg"
  }
}

resource "aws_security_group" "test_lambda_sg" {
  name        = "private-test-lambda-sg"
  description = "Allow traffic from and to lambda"
  vpc_id      = aws_vpc.test_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.1.0.0/16"]
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

resource "aws_security_group" "test_bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH inbound traffic to Bastion Host"
  vpc_id      = aws_vpc.test_vpc.id

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