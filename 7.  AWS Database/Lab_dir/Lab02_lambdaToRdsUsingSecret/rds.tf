resource "aws_db_instance" "lab02_rds" {
  engine                 = "mysql"
  engine_version         = "8.0"
  multi_az               = false
  identifier             = "lab02-rds-instance"
  username               = "lab02dbuser"
  password               = "lab02password"
  skip_final_snapshot    = true
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.lab02_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.lab02_db_sg.id]
  availability_zone      = "us-east-1b"
  db_name                = "lab02db"
}

resource "aws_db_subnet_group" "lab02_db_subnet_group" {
  name = "lab02-db-subnet-group"
  subnet_ids = [
    aws_subnet.lab02_private_subnet.id,   # us-east-1a
    aws_subnet.lab02_private_subnet_2.id, # us-east-1b
  ]
  tags = {
    Name = "lab02-db-subnet-group"
  }
}