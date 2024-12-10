#### A. Objective
(+) Demonstrate the use of IAM policy for different user's accesses to a resource.
(+) Demonstrate the use of Resource policy for different user's accesses to the resource itself.
(+) Demonstrate the logic of same-account and cross-account policy validation.
(+) Getting familiar with the use of IAM Policy and Resource Policy

#### B. Knowledge
(+) IAM Policy or Identity-based Policy is one of the two `granting policy`, the other is Resource Policy. `Granting Policy` is policy that grants its entity access to a resource, or granting access from other to itself. Different from `limiting policy` which will limit the access.

(+) IAM Policy contains `Version`, `Statement`, `Effect`, `Action`, `Resource`.

(+) In term of IAM Policy, there are two ways of granting policies, `Inline Policy` and `Attached Policy`. `Inline Policy` is the policy attached directly to the  user, and it will be destroyed if the user is terminated (no reusability). `Attached Policy`, however, is either `Customer Policy`, meaning we create the policy, or `Managed Policy`, meaning we use the policy made by AWS, and attached to multiple users, groups, entities. This way, the policy is reusable and will not be terminated even if its entity is terminated

(+) Resource Policy contains `Version`, `Statement`, `Effect`, `Action`, `Resource`, `Principal`. This has `Principal` because we are allowing `Principal` to access `ourself (as a resource)`, while for `IAM Policy` we are allowing ourself to access other resource, so `Principal` is not needed.`

(+) So, an` IAM policy` is attached to an `identity` like user, group or role, and an AWS `resource policy` is attached to a `resource` like S3, KMS, Lambda, etc.

(+) `For Intra-Account Access`: the total permission applicable to an AWS principal is the **addition** of the permissions provided in the IAM policy and Resource policy. The `implicit deny` is by default, the `explicit deny` will override `explicit allow`.

(+) `For Cross-Account Access`: Cross-Account access means that a principal in one AWS account sends a request to access the resources of another AWS account. In this case, AWS allows the cross-account request only when explicit allows are made in **_both_** the `IAM policy` (attached to the principal requesting access) and `Resource Policy`.

(+) Example of `IAM Policy` and `Resource Policy`:

``` IAM Policy
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::example-bucket/*"
        }
    ]
}
//Allow the granted user to GetObject and PubObject to files in S3 bucket named example-bucket
```

``` Resource
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::123456789012:user/ExampleUser"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::example-bucket/*"
        }
    ]
}
//Allow Principal named ExampleUser to GetObject and PubObject to files in S3 bucket named example-bucket
```

#### C. Cases
1. Create two Identity-based policy, attach to the same user and demonstrate its access to a resource.
2. Create a resource policy, create another user, attach to the first user, demonstrate the access of the two users.
3. Create a user in a different account, apply IAM policy to it, create a resource in another account. Check whether the user can access the resource. Apply a resource policy allowing the user to access and recheck if the user can now access the resource.

##### Case 1

###### First we will create a user using Terraform.
```
terraform {
  required_providers {
    aws = {
        soruce = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

# Reference to an AWS Account, that will be used to create resource
provider "aws" {
  alias = "account_A"
  profile = "cloud_user"
  region = "us-east-1"

}

# Create user A
resource "aws_iam_user" "s3_test_user" {
  provider = aws.account_A
  name = "s3-test-user"
}
```

