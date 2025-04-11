terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias   = "account_A"
  profile = "CloudDefault"
  region  = "us-east-1"
  #access_key              = "YOUR_ACCESS_KEY"
  #secret_key              = "YOUR_SECRET_KEY"
  /*
    assume_role {
        role_arn     = "arn:aws:iam::123456789012:role/RoleToAssume"
        session_name = "terraform"
        external_id  = "your-external-id"
    }*/
}

resource "aws_iam_user" "test_userA" {
  provider = aws.account_A
  name     = "test_userA"
  #permissions_boundary = "arn:aws:iam::123456789012:policy/DevPolicyBoundary"
  #force_destroy = true
  /*
    tags = {
        Environment = "dev"
        Team        = "backend"
    }*/
}

resource "aws_iam_access_key" "test_UserA_Key" {
  provider = aws.account_A
  user     = aws_iam_user.test_userA.name
}

resource "aws_iam_policy" "EC2RunOnly_policy" {
  name = "EC2RunOnlyPolicy"
  description = "Policy to allow EC2 Run Only"
  policy = file("EC2RunOnly.json")
}


resource "aws_iam_policy" "EC2DescribeOnly_policy" {
  name = "EC2DescribeOnlyPolicy"
  description = "Policy to describe EC2 only"
  policy = file("EC2DescribeOnly.json")
}



resource "aws_iam_user_policy_attachment" "test_userA_PolicyAttachment" {
    provider = aws.account_A
    user = aws_iam_user.test_userA.name
    #policy_arn = aws_iam_policy.EC2RunOnly_policy.arn
    policy_arn = aws_iam_policy.EC2DescribeOnly_policy.arn
}
