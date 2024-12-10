output "s3_test_user_access_key_id" {
  description = "The access key ID for the S3 test user"
  value       = aws_iam_access_key.s3_test_user_key.id
  sensitive   = true
}

output "s3_test_user_secret_access_key" {
  description = "The secret access key for the S3 test user"
  value       = aws_iam_access_key.s3_test_user_key.secret
  sensitive   = true
}
