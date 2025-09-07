    provider "aws" {
  region  = "us-east-1"
  profile = "lab_account"
}

locals {
  accessor_account_id = file("${path.module}/accessor_account_id.txt")
}

resource "aws_s3_bucket" "shared_bucket" {
  bucket = "cross-account-shared-bucket-example"
  force_destroy = true
}

resource "aws_iam_role" "accessor_role" {
  name = "AccessorS3FullAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Effect = "Allow",
        Principal: {
          AWS = "arn:aws:iam::${local.accessor_account_id}:root"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "access_s3_policy" {
  name = "S3FullAccessPolicy"
  role = aws_iam_role.accessor_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Effect = "Allow",
        Action = "s3:*",
        Resource = "*"
      }
    ]
  })
}