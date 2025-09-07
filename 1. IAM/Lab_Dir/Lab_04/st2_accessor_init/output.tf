output "s3_access_user_Key_Credentials" {
  value = {
    access_key = aws_iam_access_key.s3_access_user_Key.id
    secret_key = aws_iam_access_key.s3_access_user_Key.secret
    s3_access_user_ARN  = aws_iam_user.accessor_user.arn
    s3_access_user_Id   = aws_iam_user.accessor_user.id
  }
  sensitive = true
}

#terraform output -json s3_access_user_Key_Credentials to show the credentials