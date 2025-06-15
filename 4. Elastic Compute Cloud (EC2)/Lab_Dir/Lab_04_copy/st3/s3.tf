locals {
  accessor_account_id = file("${path.module}/accessor_account_id.txt")
}

resource "aws_s3_bucket" "shared_bucket" {
  bucket        = "cross-account-shared-bucket-example"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "shared_bucket_pab" {
  bucket                  = aws_s3_bucket.shared_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "cross_account_role_for_s3usage" {
  name = "RoleForS3Put"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${local.accessor_account_id}:role/EC2AssumeRole"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Description = "Role for Accessor to assume"
  }
}

resource "aws_iam_policy" "s3_put_object_policy" {
  name = "AllowS3PutObject"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = "${aws_s3_bucket.shared_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role       = aws_iam_role.cross_account_role_for_s3usage.name
  policy_arn = aws_iam_policy.s3_put_object_policy.arn
}