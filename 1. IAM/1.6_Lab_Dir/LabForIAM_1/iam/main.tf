###### 1.3 Specify the user accounts
# No need to redefine providers here, they are inherited from root

resource "aws_iam_user" "test_userA" {
  provider = aws.account_A
  name     = "test_userA"
  #permissions_boundary = "arn:aws:iam::123456789012:policy/DevPolicyBoundary"
  #force_destroy = true
  /*
    tags = {
        Environment = "dev"
        Team        = "backend"
    }*/
}

resource "aws_iam_user" "test_userB" {
  provider = aws.account_B
  name     = "test_userB"
}

###### 1.4 Specify the user key
resource "aws_iam_access_key" "test_UserA_Key" {
  provider = aws.account_A
  user     = aws_iam_user.test_userA.name
}

resource "aws_iam_access_key" "test_UserB_Key" {
  provider = aws.account_B
  user     = aws_iam_user.test_userB.name
}

###### 1.5 Specify the policy

/*
resource "aws_iam_policy" "EC2RunOnly_policy" {
  name        = "EC2RunOnlyPolicy"
  description = "Policy to allow EC2 Run Only"
  policy      = file("./Policies_Dir/EC2RunOnly.json")
}

resource "aws_iam_policy" "EC2DescribeOnly_policy" {
  name        = "EC2DescribeOnlyPolicy"
  description = "Policy to describe EC2 only"
  policy      = file("./Policies_Dir/EC2DescribeOnly.json")
}
*/

resource "aws_iam_policy" "S3AllowCrossAccountGetOBjecct" {
  name        = "S3AllowCrossAccountGetOBjecct"
  description = "Policy to allow user to getobject cross account"
  policy      = file("./Policies_Dir/AllowcrossAccountGetObject.json")
}

###### 1.6 Specify the policy attachment
/*
resource "aws_iam_user_policy_attachment" "test_userA_PolicyAttachment" {
  provider = aws.account_A
  user     = aws_iam_user.test_userA.name
  #policy_arn = aws_iam_policy.EC2RunOnly_policy.arn
  policy_arn = aws_iam_policy.EC2DescribeOnly_policy.arn
}
*/

resource "aws_iam_user_policy_attachment" "userB_Cros_GetObject" {
  provider = aws.account_B
  user     = aws_iam_user.test_userB.name
  #policy_arn = aws_iam_policy.EC2RunOnly_policy.arn
  policy_arn = aws_iam_policy.S3AllowCrossAccountGetOBjecct.arn
}