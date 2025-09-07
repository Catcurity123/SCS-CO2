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
resource "aws_iam_user" "s3_access_user" {
  name = "s3-access-user"
}

resource "aws_iam_access_key" "s3_access_user_key" {
  user = aws_iam_user.s3_access_user.name
}

//S3 admin user
resource "aws_iam_user" "s3_admin_user" {
  name = "s3-admin-user"
}

resource "aws_iam_access_key" "s3_admin_user_key" {
  user = aws_iam_user.s3_admin_user.name
}


//S3 Bucket
resource "aws_s3_bucket" "s3_test_bucket" {
  bucket = "s3-test-bucket-123453424443"
}

//List role for access user
resource "aws_iam_role" "s3_list_role" {
  name               = "s3-list-role"
  assume_role_policy = templatefile("${path.module}/IAM_Policy/AssumeRole.json", {
    aws_user = aws_iam_user.s3_access_user.arn
  })
}

resource "aws_iam_role_policy" "s3_list_role_policy" {
  name = "s3-list-policy"
  role = aws_iam_role.s3_list_role.id
  policy = templatefile("${path.module}/IAM_Policy/s3ListPolicy.json", {
    aws_s3_bucket_arn = aws_s3_bucket.s3_test_bucket.arn
  })
}

//Admin role for admin user
resource "aws_iam_role" "s3_admin_role" {
  name               = "s3-admin-role"
  assume_role_policy = templatefile("${path.module}/IAM_Policy/AssumeRole.json", {
    aws_user = aws_iam_user.s3_admin_user.arn
  })
}

resource "aws_iam_role_policy" "s3_admin_role_policy" {
  name = "s3-admin-policy"
  role = aws_iam_role.s3_admin_role.id
  policy = file("${path.module}/IAM_Policy/s3Admin.json")
}

output "s3_list_role_arn" {
  value = aws_iam_role.s3_list_role.arn
}

output "s3_admin_role_arn" {
  value = aws_iam_role.s3_admin_role.arn
}

output "s3_access_user_Key_Credentials" {
  value = {
    access_key         = aws_iam_access_key.s3_access_user_key.id
    secret_key         = aws_iam_access_key.s3_access_user_key.secret
    s3_access_user_ARN = aws_iam_user.s3_access_user.arn
    s3_access_user_Id  = aws_iam_user.s3_access_user.id
  }
  sensitive = true
}

output "s3_admin_user_Key_Credentials" {
  value = {
    access_key         = aws_iam_access_key.s3_admin_user_key.id
    secret_key         = aws_iam_access_key.s3_admin_user_key.secret
    s3_access_user_ARN = aws_iam_user.s3_admin_user.arn
    s3_access_user_Id  = aws_iam_user.s3_admin_user.id
  }
  sensitive = true
}

#terraform output -json s3_access_user_Key_Credentials to show the credentials

/*
aws sts assume-role --role-arn arn:aws:iam::637423222455:role/s3-list-role \
> --role-session-name test-s3-session \
> --profile s3-access-user
*/

//current_account = "471112659821"
//s3_access_user_Key_Credentials = <sensitive>
//s3_admin_role_arn = "arn:aws:iam::471112659821:role/s3-admin-role"
//s3_admin_user_Key_Credentials = <sensitive>
//s3_list_role_arn = "arn:aws:iam::471112659821:role/s3-list-role"
