# 1. Execution role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

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
  role          = aws_iam_role.iam_for_lambda.arn

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "provided.al2"
  handler = "bootstrap"

/*   vpc_config {
    subnet_ids         = [aws_subnet.lab01_private_subnet.id]
    security_group_ids = [aws_security_group.lab01_lambda_sg.id]
  } */

}

/* aws lambda invoke \
  --function-name go_terraform_lambda \
  --log-type Tail \
  output.json */