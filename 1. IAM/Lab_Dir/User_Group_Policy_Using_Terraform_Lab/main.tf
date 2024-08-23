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
  users = ["user-1", "user-2", "user-3"]
  groups = ["S3-Support", "EC2-Support", "EC2-Admin"]

  # Map users to groups
  user_to_group = { for i, user in local.users : user => local.groups[i] }

  # Map policies to groups
  group_to_policy = {
    "S3-Support"  = aws_iam_policy.s3_support.arn,
    "EC2-Support" = aws_iam_policy.ec2_support.arn,
    "EC2-Admin"   = aws_iam_policy.ec2_admin.arn
  }
}

# Create IAM users
resource "aws_iam_user" "users" {
  for_each = toset(local.users)
  name     = each.value
}

# Create IAM groups
resource "aws_iam_group" "groups" {
  for_each = toset(local.groups)
  name     = each.value
}

# Create policies
resource "aws_iam_policy" "s3_support" {
  name        = "S3-Support"
  description = "Policy for S3 Support"
  policy      = file("${path.module}/AmazonS3ReadOnlyAccess.json")
}

resource "aws_iam_policy" "ec2_support" {
  name        = "EC2-Support"
  description = "Policy for EC2 Support"
  policy      = file("${path.module}/AmazonEC2ReadOnlyAccess.json")
}

resource "aws_iam_policy" "ec2_admin" {
  name        = "EC2-Admin"
  description = "Policy for EC2 Admin"
  policy      = file("${path.module}/ec2-admin.json")
}

# Attach Policies to Groups
resource "aws_iam_group_policy_attachment" "group_policy_attachments" {
  for_each = local.group_to_policy
  group    = aws_iam_group.groups[each.key].name
  policy_arn = each.value
}

# Attach each user to their respective group
resource "aws_iam_user_group_membership" "user_group_memberships" {
  for_each = local.user_to_group
  user     = aws_iam_user.users[each.key].name
  groups   = [each.value]
}
