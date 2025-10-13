provider "aws" {
  region  = "us-east-1"
  profile = "lab_account"
}

data "aws_caller_identity" "current" {}

output "creator_account_id" {
  value = data.aws_caller_identity.current.account_id
}