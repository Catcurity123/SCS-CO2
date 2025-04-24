
##### Case 2 Demonstrate the use of Resource policy
###### 2.1 Create S3 Bucket

resource "aws_s3_bucket" "s3_test_bucket" {
  provider = aws.account_A
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
  template = file("${path.module}/../Policies_Dir/S3BucketLevelPolicy.json")
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

#-------------------------------------------------#

data "template_file" "s3_object_level_policy_template" {
  template = file("${path.module}/../Policies_Dir/S3ObjectLevelPolicy.json")
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

#-------------------------------------------------#

data "template_file" "s3_cross_account_getobject" {
  template = file("${path.module}/../Policies_Dir/AllowUserGetObject.json")
  vars = {
    aws_s3_bucket_arn = aws_s3_bucket.s3_test_bucket.arn
    aws_userb_arn = aws_iam_user.test_userB.arn
  }
}

resource "aws_s3_bucket_policy" "s3_cross_account_getobject_policy" {
    bucket = aws_s3_bucket.s3_test_bucket.id
    policy = data.template_file.s3_cross_account_getobject.rendered
}


resource "aws_iam_user_policy_attachment" "s3_bucket_level_policy_attachment" {
    provider = aws.account_A
    user = aws_iam_user.test_userA.name
    policy_arn = aws_iam_policy.s3_bucket_level_policy.arn
}

# Attach the policy onto the user
resource "aws_iam_user_policy_attachment" "s3_object_level_policy_attachment" {
    provider = aws.account_A
    user = aws_iam_user.test_userA.name
    policy_arn = aws_iam_policy.s3_object_level_policy.arn
}

# Attach resource policy
resource "aws_s3_bucket_policy" "s3_cross_account_getobject_policy_attachment" {
    bucket = aws_s3_bucket.s3_test_bucket.id
    policy = data.template_file.s3_cross_account_getobject.rendered
}