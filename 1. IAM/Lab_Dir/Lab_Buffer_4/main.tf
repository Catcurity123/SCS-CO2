terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider for Account A
provider "aws" {
  alias   = "account_A"
  profile = "lab_account"
  region  = "us-east-1"
}

# Provider for Account B
provider "aws" {
  alias   = "account_B"
  profile = "main_account"
  region  = "us-east-1"
}

# Policy for Account A (Listing all S3 Buckets)
resource "aws_iam_policy" "example_policy" {
  provider = aws.account_A
  name        = "ExampleS3ListPolicy"
  description = "A policy that allows listing all S3 buckets"
  policy      = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action   = "s3:ListAllMyBuckets"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::*"
      }
    ]
  })
}

# User in Account A
resource "aws_iam_user" "test_userA" {
  provider = aws.account_A
  name     = "test-user-A"
}

# Attach the policy to the user in Account A
resource "aws_iam_user_policy_attachment" "test_userA_policy" {
  provider = aws.account_A
  user     = aws_iam_user.test_userA.name
  policy_arn = aws_iam_policy.example_policy.arn
}

# Cross-Account Role in Account A
resource "aws_iam_role" "cross_account_role" {
  provider = aws.account_A
  name     = "CrossAccountRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Principal = {
          AWS = aws_iam_user.test_userB.arn
        }
        Action   = "sts:AssumeRole"
      }
    ]
  })
}

# User in Account B
resource "aws_iam_user" "test_userB" {
  provider = aws.account_B
  name     = "test-user-B"
}

