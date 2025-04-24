
output "userA_Credentials" {
  value = {
    access_key = aws_iam_access_key.test_UserA_Key.id
    secret_key = aws_iam_access_key.test_UserA_Key.secret
    userA_ARN  = aws_iam_user.test_userA.arn
    userA_Id   = aws_iam_user.test_userA.id
  }
  sensitive = true
}
#terraform output -json userA_Credentials to show the credentials

output "userB_Credentials" {
  value = {
    access_key = aws_iam_access_key.test_UserB_Key.id
    secret_key = aws_iam_access_key.test_UserB_Key.secret
    userB_ARN  = aws_iam_user.test_userB.arn
    userB_Id   = aws_iam_user.test_userB.id
  }
  sensitive = true
}


output "userA_Policy_Info" {
  value = {
    policy_id               = aws_iam_policy.EC2RunOnly_policy.id
    policy_arn              = aws_iam_policy.EC2RunOnly_policy.arn
    policy_attachment_count = aws_iam_policy.EC2RunOnly_policy.attachment_count
  }
}

output "S3_Info" {
  value = {
    s3_arn     = aws_s3_bucket.s3_test_bucket.arn
    s3_version = aws_s3_bucket_versioning.s3_test_bucket_version.versioning_configuration
    s3_policy_arn = aws_iam_policy.s3_bucket_level_policy.arn
  }
}