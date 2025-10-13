#!/bin/bash

# Prompt for inputs
read -p "Enter source profile (from ~/.aws/credentials): " SOURCE_PROFILE
read -p "Enter role ARN to assume: " ROLE_ARN
read -p "Enter session name: " SESSION_NAME

# Call STS to assume the role
CREDENTIALS=$(aws sts assume-role \
  --profile "$SOURCE_PROFILE" \
  --role-arn "$ROLE_ARN" \
  --role-session-name "$SESSION_NAME" \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

echo "DEBUG: Raw credentials output:"
echo "$CREDENTIALS"


# Split credentials into variables
AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | awk '{print $1}')
AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | awk '{print $2}')
AWS_SESSION_TOKEN=$(echo $CREDENTIALS | awk '{print $3}')

# Export credentials
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

echo
aws sts get-caller-identity --output table 2>/dev/null || echo "Failed to authenticate with provided credentials."

