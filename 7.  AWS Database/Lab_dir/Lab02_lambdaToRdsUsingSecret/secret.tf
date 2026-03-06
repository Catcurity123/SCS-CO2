resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "lab02-rds-credentials"
  description = "RDS MySQL credentials"
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "lab02dbuser"
    password = "lab02password"
    host     = aws_db_instance.lab02_rds.address
    dbname   = "lab02db"
  })
}