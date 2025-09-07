provider "aws" {
  region  = "us-east-1"
  profile = "lab_account"
}

//https://awspolicygen.s3.amazonaws.com/policygen.html

data "aws_caller_identity" "current" {}

output "current_account" {
  value = data.aws_caller_identity.current.account_id
}

//S3 access user
resource "aws_iam_user" "test_user2" {
  name = "test-user2"
}

resource "aws_iam_access_key" "test_user2_key" {
  user = aws_iam_user.test_user2.name
}
#terraform output -json test_user_creds to show the credentials


//S3 Bucket
resource "aws_s3_bucket" "s3_test_bucket" {
  bucket        = "s3-testbucket-sfsfsdfsfw"
  force_destroy = true
  tags = {
    Environment = "test"
  }
}

//S3 Resource Policy
resource "aws_s3_bucket_policy" "bucket_list_policy" {
  bucket = aws_s3_bucket.s3_test_bucket.id
  policy = templatefile("${path.module}/Resource_Policy/AllowUserGetObjectS3.json", {
    aws_s3_bucket_arn = aws_s3_bucket.s3_test_bucket.arn
    aws_user_arn = aws_iam_user.test_user2.arn
  })
}


//Output
output "test_user_creds" {
  value = {
    access_key         = aws_iam_access_key.test_user2_key.id
    secret_key         = aws_iam_access_key.test_user2_key.secret
    test_user_ARN = aws_iam_user.test_user2.arn
    test_user_Id  = aws_iam_user.test_user2.id
  }
  sensitive = true
}