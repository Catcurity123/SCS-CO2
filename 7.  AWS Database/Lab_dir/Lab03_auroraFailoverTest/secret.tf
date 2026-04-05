resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "lab03-rds-credentials"
  description = "RDS MySQL credentials"
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "lab03dbuser"
    password = "lab03password"
    host     = aws_rds_cluster.lab03_aurora.endpoint
    dbname   = "lab03db"
  })
}