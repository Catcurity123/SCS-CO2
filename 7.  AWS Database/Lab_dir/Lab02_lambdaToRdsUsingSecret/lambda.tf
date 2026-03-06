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
  name               = "iam_for_lambda_lab02"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

///
resource "aws_iam_role_policy" "lambda_secrets_policy" {
  name = "lambda-secrets-policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.rds_credentials.arn
      }
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/Go_Dir/bootstrap" # ← change from main.go to bootstrap
  output_path = "go_lambda_src.zip"
}

resource "aws_lambda_function" "lambda" {
  filename      = "go_lambda_src.zip"
  function_name = "go_terraform_lambda_rds_secret"
  role          = aws_iam_role.iam_for_lambda.arn

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "provided.al2" # ← go1.x is deprecated
  handler = "bootstrap"

  vpc_config {
    subnet_ids         = [aws_subnet.lab02_private_subnet.id]
    security_group_ids = [aws_security_group.lab02_lambda_sg.id]
  }

  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.rds_credentials.arn
    }
  }
}

