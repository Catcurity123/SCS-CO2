output "s3_information" {
  value = {
    s3_role_arn    = aws_iam_role.cross_account_role_for_s3usage.arn
    s3_bucket_name = aws_s3_bucket.shared_bucket.bucket
  }
}