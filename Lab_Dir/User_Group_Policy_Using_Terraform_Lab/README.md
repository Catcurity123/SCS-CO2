# Objective - Day 1

(+) Create 3 users, assign them to 3 different groups.

(+) Groups consists of different permission levels (S3_Support, S3_Admin, EC2_Support).

(+) Create Login Profile for 3 users, allow them to have the same password, reset password on first login.

# Solution Script

``` Solution Script
#!/bin/bash

# Create Groups
aws iam create-group --group-name S3_Support
aws iam create-group --group-name S3_Admin
aws iam create-group --group-name EC2_Support

# Attach Policies to Groups
aws iam attach-group-policy --group-name S3_Support --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws iam attach-group-policy --group-name S3_Admin --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam attach-group-policy --group-name EC2_Support --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess


# Create Users
aws iam create-user --user-name user1
aws iam create-user --user-name user2
aws iam create-user --user-name user3

# Add Users to Groups
aws iam add-user-to-group --group-name S3_Support --user-name user1
aws iam add-user-to-group --group-name S3_Admin --user-name user2
aws iam add-user-to-group --group-name EC2 --user-name user3

# Create Login Profiles
aws iam create-login-profile --user-name user1 --password "YourCommonPassword123" --password-reset-required
aws iam create-login-profile --user-name user2 --password "YourCommonPassword123" --password-reset-required
aws iam create-login-profile --user-name user3 --password "YourCommonPassword123" --password-reset-required
```