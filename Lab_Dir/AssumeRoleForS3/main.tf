terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Reference two AWS Accounts 
provider "aws" {
  alias = "s3-account"    # Account that has the S3 and the Assume role
  profile = "cloud_user"
  region  = "us-east-1"
}

provider "aws"{
    alias = "assume-account"  # Account that has the user that will assume the role for S3 Admin Access
    profile = "default"
    region = "us-east-1"
}

# We want a user on Account A (assume-account) to assume a role (on Account B) that have S3AdminPermission on Account B (s3-account)
# For cross-account access to work, we need to explicitly allow the access from both principlles.
# That is, the user on Account A has to have allow permission to assume a role, and the role must also allow the user on Account A to assume.
# On same account access, only one of them having the allow permission is enough.


# Create the user on Account A
resource "aws_iam_user" "s3_admin" {
  provider = aws.assume-account    # Refer to which account we want the resource to be in
  name = "s3-admin"
}

# Create the outbound assume policy for S3 Admin
resource "aws_iam_policy" "s3_admin_assume_policy" {
  provider = aws.assume-account
  name        = "S3AdminAssumePolicy"
  description = "Allow AssumeRole for S3 Admin"
  policy = file("${path.module}/AssumeRolePolicyOutbound.json") # Refer to the policy for better readability
}

# Attach the Assume Policy to the S3 Admin
resource "aws_iam_user_policy_attachment" "s3_admin_policy" {
    provider = aws.assume-account
    user = aws_iam_user.s3_admin.name
    policy_arn = aws_iam_policy.s3_admin_assume_policy.arn
}

# Create a template file for the Inbound Assume Policy 
data "template_file" "assume_role_policy_template" {
  template = file("${path.module}/AssumeRolePolicyInbound.json")
  # Refer the variable in the policy
  vars = {
    aws_assumer_arn = aws_iam_user.s3_admin.arn
  }
}

# Create IAM Policy for the assumed role 
resource "aws_iam_policy" "s3_full_access_policy" {
  provider = aws.s3-account
  name        = "S3FullAccess"
  description = "S3 full access policy"

  policy = file("${path.module}/S3FullAdmin.json")
}

# Create An Assumed Role, attached the trust policy to the assumed role
resource "aws_iam_role" "s3_assume_role" {
    provider = aws.s3-account
    name = "s3-assume-role"
    assume_role_policy = data.template_file.assume_role_policy_template.rendered
}

# Attach the permission policy to the assumed role, by this the assumed role will have both the trust policy and permission policy
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  provider = aws.s3-account
  role       = aws_iam_role.s3_assume_role.name
  policy_arn = aws_iam_policy.s3_full_access_policy.arn
}

