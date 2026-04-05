# 1. Execution role

## 1.1 AssumeRole Policy for Lambda
data "aws_iam_policy_document" "assume_role" { //Policy template
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

## 1.2 Execution role for lambda, trust policy
resource "aws_iam_role" "execution_role_lambda" { //Assign policy tempalte to a role, trust policy
  name               = "execution-role-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

## 1.3 Permission policy granting S3 Access to Lamda's Execution role
resource "aws_iam_role_policy" "lambda_s3_access_role" { //Assign permission policy to a role
  name = "lambda-s3-access-policy"
  role = aws_iam_role.execution_role_lambda.id
  policy = templatefile("${path.module}/policy_prep_fold/s3Access.json", {
    aws_s3_source_bucket_arn = aws_s3_bucket.source.arn
    aws_s3_dest_bucket_arn   = aws_s3_bucket.destination.arn
  })
}


## 1.4 Resource policy for Lambda
data "aws_caller_identity" "current" {}

resource "aws_lambda_permission" "allow_s3" {
  statement_id   = "AllowS3Invoke"
  action         = "lambda:InvokeFunction"                     //To perform this action 3
  function_name  = aws_lambda_function.lambda.function_name    //On this function 4
  principal      = "s3.amazonaws.com"                          //Allow this Principal 1
  source_arn     = aws_s3_bucket.source.arn                    //Particularly this bucket 2
  source_account = data.aws_caller_identity.current.account_id //Of this account 5
}

/* 4. Confused Deputy Problem

Without source_account:

Your Lambda allows s3.amazonaws.com.
The only restriction is source_arn.
If a malicious actor manages to create or control a bucket with the same ARN context, S3 could invoke your Lambda on their behalf. 
*/

# 2. Code zipped
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/Go_Dir/bootstrap"
  output_path = "go_lambda_src.zip"
}

# 3. Lambda configuration and runtime 
resource "aws_lambda_function" "lambda" {
  filename      = "go_lambda_src.zip"
  function_name = "go_terraform_lambda"
  role          = aws_iam_role.execution_role_lambda.arn

  source_code_hash = data.archive_file.lambda.output_base64sha256
  architectures    = ["x86_64"]
  timeout          = 30

  runtime = "provided.al2"
  handler = "bootstrap"

  environment {
    variables = {
      DEST_BUCKET = aws_s3_bucket.destination.id
    }
  }
  /*   vpc_config {
    subnet_ids         = [aws_subnet.lab02_private_subnet.id]
    security_group_ids = [aws_security_group.lab02_lambda_sg.id]
  } */

}

# 4. S3 Event notification
resource "aws_s3_bucket_notification" "trigger" {
  bucket = aws_s3_bucket.source.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_permission.allow_s3]
}




/* aws lambda invoke \
  --function-name go_terraform_lambda \
  --log-type Tail \
  output.json */