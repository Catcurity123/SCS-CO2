provider "aws" {
  region  = "us-east-1"
  profile = "main_account"
}

locals {
  creator_account_id = file("${path.module}/creator_account_id.txt")
}

data "aws_caller_identity" "current" {}

resource "aws_iam_user" "accessor_user" {
  name = "s3-access-user"
}

resource "aws_iam_access_key" "s3_access_user_Key" {
  user     = aws_iam_user.accessor_user.name
}

resource "aws_iam_policy" "assume_creator" {
  name = "AssumeCreatorRole"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Effect = "Allow",
        Action = ["sts:AssumeRole"],
        Resource = "arn:aws:iam::${local.creator_account_id}:role/AccessorS3FullAccessRole"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_assume_policy" {
  user       = aws_iam_user.accessor_user.name
  policy_arn = aws_iam_policy.assume_creator.arn
}

output "accessor_account_id" {
  value = data.aws_caller_identity.current.account_id
}
