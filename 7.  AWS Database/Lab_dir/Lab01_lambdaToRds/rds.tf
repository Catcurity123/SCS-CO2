resource "aws_db_instance" "test_rds" {
  engine                 = "mysql"
  engine_version         = "8.0"
  multi_az               = false
  identifier             = "test-rds-instance"
  username               = "testdbuser"
  password               = "testpassword"
  skip_final_snapshot    = true
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.test_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.test_db_sg.id]
  availability_zone      = "us-east-1b"
  db_name                = "testdb"
}

resource "aws_db_subnet_group" "test_db_subnet_group" {
  name = "test-db-subnet-group"
  subnet_ids = [
    aws_subnet.test_private_subnet.id,   # us-east-1a
    aws_subnet.test_private_subnet_2.id, # us-east-1b
  ]
  tags = {
    Name = "test-db-subnet-group"
  }
}

/* 
mysql -h test-rds-instance.ci5oiekqmq9c.us-east-1.rds.amazonaws.com \
-u testdbuser \
-p \
testdb

 */