# Aurora Cluster — holds the shared storage volume (persists independently of compute)
resource "aws_rds_cluster" "lab03_aurora" {
  cluster_identifier     = "lab03-aurora-cluster"
  engine                 = "aurora-mysql"
  engine_version         = "8.0.mysql_aurora.3.10.3"
  master_username        = "lab03dbuser"
  master_password        = "lab03password"
  database_name          = "lab03db"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.lab03_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.lab03_db_sg.id]
}

# Aurora Instance — compute node that attaches to the cluster volume above
resource "aws_rds_cluster_instance" "lab03_aurora_writer" {
  identifier         = "lab03-aurora-writer"
  cluster_identifier = aws_rds_cluster.lab03_aurora.id
  instance_class     = "db.t3.medium" # db.t3.micro is not supported by Aurora
  engine             = aws_rds_cluster.lab03_aurora.engine
  engine_version     = aws_rds_cluster.lab03_aurora.engine_version
}

resource "aws_db_subnet_group" "lab03_db_subnet_group" {
  name = "lab03-db-subnet-group"
  subnet_ids = [
    aws_subnet.lab03_private_subnet.id,   # us-east-1a
    aws_subnet.lab03_private_subnet_2.id, # us-east-1b
  ]
  tags = {
    Name = "lab03-db-subnet-group"
  }
}
