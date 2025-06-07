provider "aws" {
  region  = "us-east-1"
  profile = "lab_account"
}

data "aws_caller_identity" "current" {}
