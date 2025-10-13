provider "aws" {
  region  = "us-east-1"
  profile = "lab_account"
}

//https://awspolicygen.s3.amazonaws.com/policygen.html

data "aws_caller_identity" "current" {}

output "current_account" {
  value = data.aws_caller_identity.current.account_id
}

//S3 access user
resource "aws_iam_user" "test_user" {
  name = "test-user"
}

resource "aws_iam_access_key" "test_user_key" {
  user = aws_iam_user.test_user.name
}
#terraform output -json test_user_creds to show the credentials


//IAM Policy for test

resource "aws_iam_policy" "S3List_policy" {
  name        = "S3List"
  description = "Policy to allow EC2 Run Only"
  policy      = file("${path.module}/IAM_Policy/S3ListOnly.json")
}

resource "aws_iam_policy" "EC2Desribe_policy" {
  name        = "EC2Describe"
  description = "Policy to allow EC2 Run Only"
  policy      = file("${path.module}/IAM_Policy/EC2DescribeOnly.json")
}


//S3 Bucket
resource "aws_s3_bucket" "s3_test_bucket" {
  bucket = "s3-test-bucket-123453424443"
}

//EC2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Resource to launch the EC2 instance in the public subnet
resource "aws_instance" "example_web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  tags = {
    Name = "latest-amazon-linux-2-public"
  }
}

//Ouutput
output "test_user_creds" {
  value = {
    access_key         = aws_iam_access_key.test_user_key.id
    secret_key         = aws_iam_access_key.test_user_key.secret
    test_user_ARN = aws_iam_user.test_user.arn
    test_user_Id  = aws_iam_user.test_user.id
  }
  sensitive = true
}

//aws s3api create-bucket --bucket <> --region <>
