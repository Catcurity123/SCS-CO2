data "aws_region" "current" {}

resource "aws_iam_role" "ec2_cloudwatch" {
  name = "EC2CloudWatchRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "Description" = "Role for EC2 to send logs to CloudWatch and communicate with SSM"
  }
}

# Attach SSM managed instance core policy (includes ssm:GetParameter)
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent Server Policy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_cloudwatch_profile" {
  name = "EC2CloudWatchProfile"
  role = aws_iam_role.ec2_cloudwatch.name
}


# IAM Role for EC2 with Full Administrator Access
resource "aws_iam_role" "ec2_admin" {
  name = "EC2AdminRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Description = "Role for EC2 instances with full administrator permissions"
  }
}

# Attach the AWS managed AdministratorAccess policy
resource "aws_iam_role_policy_attachment" "ec2_admin_attach" {
  role       = aws_iam_role.ec2_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Create an instance profile for the EC2AdminRole
resource "aws_iam_instance_profile" "ec2_admin_profile" {
  name = "EC2AdminInstanceProfile"
  role = aws_iam_role.ec2_admin.name
}

