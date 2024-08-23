terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "cloud_user"
  region  = "us-east-1"
}

locals {
  tags = {
    project = "test-lab"
  }
}

# Create user
resource "aws_iam_user" "s3_admin" {
  name = "s3-admin"
}

# Create and attach IAM policy
resource "aws_iam_user_policy" "s3_admin_policy" {
  name        = "S3-Admin-Policy"
  policy      = file("${path.module}/AmazonS3FullAccess.json")
  user = aws_iam_user.s3_admin.name
}

# Create S3 bucket
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "test-bucket-for-labbing"
  force_destroy = false

  tags = local.tags
}

# Create S3 Policy
data "template_file" "s3_restrict_policy" {
  template = file("${path.module}/S3ResourcePolicy.json")

  vars = {
    aws_iam_user_arn = aws_iam_user.s3_admin.arn
    bucket_arn       = aws_s3_bucket.s3_bucket.arn
  }
}

# Apply the S3 bucket policy
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.template_file.s3_restrict_policy.rendered
}
