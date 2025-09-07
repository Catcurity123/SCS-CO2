output "accessor_role" {
  value = {
    accessor_role_arn = aws_iam_role.accessor_role.arn  
  }
  sensitive = true
}

/*

aws sts assume-role \
  --role-arn arn:aws:iam::<target_account_id>:role/<role_name> \
  --role-session-name <session_name>

*/

#terraform output -json userA_Credentials to show the credentials
