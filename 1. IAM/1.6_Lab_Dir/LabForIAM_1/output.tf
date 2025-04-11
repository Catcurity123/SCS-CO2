
output "userA_Credentials" {
  value = {
    access_key = aws_iam_access_key.test_UserA_Key.id
    secret_key = aws_iam_access_key.test_UserA_Key.secret
    userA_ARN  = aws_iam_user.test_userA.arn
    userA_Id   = aws_iam_user.test_userA.id
  }
  sensitive = true
}


output "userA_Policy_Info" {
  value = {
    policy_id = aws_iam_policy.EC2RunOnly_policy.id
    policy_arn = aws_iam_policy.EC2RunOnly_policy.arn
    policy_attachment_count = aws_iam_policy.EC2RunOnly_policy.attachment_count 
  }
}