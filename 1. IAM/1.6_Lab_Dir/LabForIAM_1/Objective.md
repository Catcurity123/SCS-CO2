#### Objective: Demonstrate the usage of permission policy
1. Create two Identity-based policy, attach to the same user and demonstrate its access to a resource.
2. Create a resource policy, create another user, attach to the first user, demonstrate the access of the two users.
3. Create a user in a different account, apply IAM policy to it, create a resource in another account. Check whether the user can access the resource. Apply a resource policy allowing the user to access and recheck if the user can now access the resource.


##### Objective 1
###### Create the environment, and a testing user
```
# Tell Terraform to use hashicorp/aws 5.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Specify the CSP and the profile [already with access key and secret key]
provider "aws" {
  alias   = "account_A"
  profile = "CloudDefault"
  region  = "us-east-1"
}

# Create a user 
resource "aws_iam_user" "test_userA" {
  provider = aws.account_A
  name     = "test_userA"
}

# Create access key for the user
resource "aws_iam_access_key" "test_UserA_Key" {
  provider = aws.account_A
  user     = aws_iam_user.test_userA.name
}
```

###### Then we will create 2 policies with different permissions, one can launch an instance, one can only view the instance
``` #EC2DescribeOnly_policy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeInstances",
      "Resource": "*"
    }
  ]
}
```

``` #EC2RunOnly_policy
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:RunInstances",
          "ec2:DescribeImages",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeKeyPairs",
          "ec2:CreateTags"
        ],
        "Resource": "*"
      }
    ]
  }
```


(+) Then we will need to attach the json policy to aws policy and attach them
```
resource "aws_iam_policy" "EC2RunOnly_policy" {
  name        = "EC2RunOnly Policy"
  description = "Policy to allow EC2 Run Only"
  policy      = file("EC2RunOnly_policy.json")
}

resource "aws_iam_user_policy_attachment" "test_userA_PolicyAttachment" {
    provider = aws.account_A
    user = aws_iam_user.test_userA.name
    policy_arn = aws_iam_policy.EC2RunOnly_policy.arn
}
```

(+) After applying, if we want to see if the user is attached with the policy
==> **aws iam list-attached-user-policies --user-name <test_userA>**

(+) And then if we want to see what the policy is about
==> **aws iam get-policy-version --policy-arn <policy_arn> --version-id v1**

==> By this way, we know how to create policies with different permissions, apply to a user and test the permissions grant to the users.

##### Objective 2
###### Create a bucket, assign bucket with resource policy

```
resource "aws_s3_bucket" "s3_test_bucket" {
  bucket        = "s3-testbucket-forscs2"
  force_destroy = true
  tags = {
    Environment = "test"
  }
}
```

```
data "template_file" "s3_bucket_level_policy_template" {
  template = file("${path.module}/S3BucketLevelPolicy.json")
  #template = file("${path.module}/S3ObjectLevelPolicy.json")
  # Refer the variable in the policy
  vars = {
    aws_s3_bucket_arn = aws_s3_bucket.s3_test_bucket.arn
  }
}

# Create aws iam policy
resource "aws_iam_policy" "s3_bucket_level_policy" {
  provider = aws.account_A
  name = "S3BucketLevelPolicy"
  #  name = "S3ObjectLevelPolicy"
  description = "Only allow bucket level actions"
  policy = data.template_file.s3_bucket_level_policy_template.rendered
}
```

```
resource "aws_iam_user_policy_attachment" "s3_bucket_level_policy_attachment" {
    provider = aws.account_A
    user = aws_iam_user.test_userA.name
    policy_arn = aws_iam_policy.s3_bucket_level_policy.arn
}
```

(+) Then attach different policeis to different users to see the different in permission.

##### Objective 3 
###### First we will allow cross-account access using Identity policy and resource policy
(+) First we will create identity policies and resource policies that will allow a user to list bucket