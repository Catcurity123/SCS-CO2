terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

# Reference to an AWS Account, that will be used to create resource
provider "aws" {
  alias = "account_A"
  profile = "cloud_user"
  region = "us-east-1"
}

# Create user A
resource "aws_iam_user" "s3_test_user" {
  provider = aws.account_A
  name = "s3-test-user"
}

resource "aws_iam_access_key" "s3_test_user_key" {
  provider = aws.account_A
  user     = aws_iam_user.s3_test_user.name
}

# Create s3 bucket for testing
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "test-bucket-for-labbingss"
  force_destroy = false
}

data "template_file" "s3_bucket_level_only_policy_template" {
  template = file("${path.module}/S3BucketLevelOnlyPolicy.json")
  #template = file("${path.module}/S3ObjectLevelPolicy.json")
  # Refer the variable in the policy
  vars = {
    aws_s3_bucket_arn = aws_s3_bucket.s3_bucket.arn
  }
}

# Create aws iam policy
resource "aws_iam_policy" "s3_bucket_level_only" {
  provider = aws.account_A
  name = "S3BucketLevelOnlyPolicy"
  #  name = "S3ObjectLevelPolicy"
  description = "Only allow bucket level actions"
  policy = data.template_file.s3_bucket_level_only_policy_template.rendered
}

# Attach the policy onto the user
resource "aws_iam_user_policy_attachment" "s3_bucket_level_only_policy" {
    provider = aws.account_A
    user = aws_iam_user.s3_test_user.name
    policy_arn = aws_iam_policy.s3_bucket_level_only.arn
}