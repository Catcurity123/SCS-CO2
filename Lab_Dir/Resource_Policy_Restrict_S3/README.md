# Objective - Day 2
(+) Create a user (S3_Admin), assign appropriate permission via IAM Policy for this user.

(+) Create a S3 bucket, limit the usage of this S3 bucket only to the S3_Admin using Resource Policy.

(+) Ensure no public access to the bucket, ensure the admin can upload and download from the bucket.

(+) Create a pre-signed S3 URL using the S3_Admin credentials, expires in 1 hour (3600 seconds)


# Solution Script

``` Solution Script
#!/bin/bash

# Variables
USER_NAME="S3_Admin"
BUCKET_NAME="test-bucket-for-labbing"
REGION="us-east-1"
POLICY_NAME="S3AdminPolicy"
POLICY_FILE="s3_admin_policy.json"
BUCKET_POLICY_FILE="bucket_policy.json"

# 1. Create IAM User
echo "Creating IAM user: $USER_NAME"
aws iam create-user --user-name $USER_NAME

# 2. Create IAM Policy for S3 Admin
echo "Creating IAM policy: $POLICY_NAME"
cat <<EOF > $POLICY_FILE
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "s3-object-lambda:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
aws iam create-policy --policy-name $POLICY_NAME --policy-document file://$POLICY_FILE

# 3. Attach Policy to User
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)
echo "Attaching policy $POLICY_NAME to user $USER_NAME"
aws iam attach-user-policy --user-name $USER_NAME --policy-arn $POLICY_ARN

# 4. Create S3 Bucket
echo "Creating S3 bucket: $BUCKET_NAME"
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION

# 5. Set Bucket Policy
echo "Setting bucket policy for $BUCKET_NAME"
cat <<EOF > $BUCKET_POLICY_FILE
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<YOUR_ACCOUNT_ID>:user/$USER_NAME"
            },
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/*"
            ]
        },
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/*"
            ],
            "Condition": {
                "StringNotEquals": {
                    "aws:username": "$USER_NAME"
                }
            }
        }
    ]
}
EOF
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://$BUCKET_POLICY_FILE

# 6. Ensure No Public Access
echo "Ensuring no public access to bucket $BUCKET_NAME"
aws s3api put-bucket-acl --bucket $BUCKET_NAME --acl private

# 7. Create a Pre-signed URL (Assuming AWS CLI profile is configured)
echo "Generating pre-signed URL for S3 object"
aws s3api put-object --bucket $BUCKET_NAME --key test-object --body /dev/null --region $REGION
PRESIGNED_URL=$(aws s3 presign s3://$BUCKET_NAME/test-object --expires-in 3600 --region $REGION)

echo "Pre-signed URL: $PRESIGNED_URL"

# Clean up
rm $POLICY_FILE
rm $BUCKET_POLICY_FILE

echo "Setup completed successfully."
```