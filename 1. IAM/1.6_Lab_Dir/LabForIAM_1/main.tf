#### IAM Lab 1

##### Case 1 Demonstrate the use of permission policy
###### 1.1 Specify the Terraform providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

###### 1.2 Specify the SCP
provider "aws" {
  alias   = "account_A"
  profile = "CloudLab"
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

###### 1.3 Specify the user accounts
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

resource "aws_iam_user" "test_userB" {
  provider = aws.account_A
  name     = "test_userB"
}

###### 1.4 Specify the user key
resource "aws_iam_access_key" "test_UserA_Key" {
  provider = aws.account_A
  user     = aws_iam_user.test_userA.name
}

resource "aws_iam_access_key" "test_UserB_Key" {
  provider = aws.account_A
  user     = aws_iam_user.test_userB.name
}

###### 1.5 Specify the policy
resource "aws_iam_policy" "EC2RunOnly_policy" {
  name        = "EC2RunOnlyPolicy"
  description = "Policy to allow EC2 Run Only"
  policy      = file("EC2RunOnly.json")
}

resource "aws_iam_policy" "EC2DescribeOnly_policy" {
  name        = "EC2DescribeOnlyPolicy"
  description = "Policy to describe EC2 only"
  policy      = file("EC2DescribeOnly.json")
}

###### 1.6 Specify the policy attachment
resource "aws_iam_user_policy_attachment" "test_userA_PolicyAttachment" {
  provider = aws.account_A
  user     = aws_iam_user.test_userA.name
  #policy_arn = aws_iam_policy.EC2RunOnly_policy.arn
  policy_arn = aws_iam_policy.EC2DescribeOnly_policy.arn
}

##### Case 2 Demonstrate the use of Resource policy
###### 2.1 Create S3 Bucket
resource "aws_s3_bucket" "s3_test_bucket" {
  bucket        = "s3-testbucket-forscs2"
  force_destroy = true
  tags = {
    Environment = "test"
  }
}

###### 2.2 Enable bucket versioning 
resource "aws_s3_bucket_versioning" "s3_test_bucket_version" {
  bucket = aws_s3_bucket.s3_test_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

###### 2.3 AWS S3 encryption using sse-s3 and sse-kms
resource "aws_s3_bucket_server_side_encryption_configuration" "sse_s3" {
  bucket = aws_s3_bucket.s3_test_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

/*
resource "aws_s3_bucket_server_side_encryption_configuration" "sse_kms" {
  bucket = aws_s3_bucket.s3_test_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.mykey.arn
    }
  }
}
*/

####### 2.3.1 If we want to use SSE-C
/*
aws s3 cp file.txt s3://my-bucket/ --sse-c-key fileb://./my_key.key
*/


###### 2.4 Create 3 S3 resource policies
data "template_file" "s3_bucket_level_policy_template" {
  template = file("${path.module}/S3BucketLevelPolicy.json")
  #template = file("${path.module}/S3ObjectLevelPolicy.json")
  # Refer the variable in the policy
  vars = {
    aws_s3_bucket_arn = aws_s3_bucket.s3_test_bucket.arn
  }
}

# Create aws iam policy
resource "aws_iam_policy" "s3_bucket_level_policy" {
  provider = aws.account_A
  name = "S3BucketLevelPolicy"
  #  name = "S3ObjectLevelPolicy"
  description = "Only allow bucket level actions"
  policy = data.template_file.s3_bucket_level_policy_template.rendered
}

resource "aws_iam_user_policy_attachment" "s3_bucket_level_policy_attachment" {
    provider = aws.account_A
    user = aws_iam_user.test_userA.name
    policy_arn = aws_iam_policy.s3_bucket_level_policy.arn
}


data "template_file" "s3_object_level_policy_template" {
  template = file("${path.module}/S3ObjectLevelPolicy.json")
  vars = {
    aws_s3_bucket_arn = aws_s3_bucket.s3_test_bucket.arn
  }
}

# Create aws iam policy
resource "aws_iam_policy" "s3_object_level_policy" {
  provider = aws.account_A
  name = "S3ObjectLevelPolicy"
  #  name = "S3ObjectLevelPolicy"
  description = "Only allow object level actions"
  policy = data.template_file.s3_object_level_policy_template.rendered
}

# Attach the policy onto the user
resource "aws_iam_user_policy_attachment" "s3_object_level_policy_attachment" {
    provider = aws.account_A
    user = aws_iam_user.test_userB.name
    policy_arn = aws_iam_policy.s3_object_level_policy.arn
}