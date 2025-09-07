#!/bin/bash
# Usage: ./assume-role-export.sh <source-profile> <role-arn> <session-name>

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <source-profile> <role-arn> <session-name>"
  exit 1
fi

SOURCE_PROFILE="$1"
ROLE_ARN="$2"
SESSION_NAME="$3"

read ACCESS_KEY SECRET_KEY SESSION_TOKEN <<< $(aws sts assume-role \
  --profile "$SOURCE_PROFILE" \
  --role-arn "$ROLE_ARN" \
  --role-session-name "$SESSION_NAME" \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
export AWS_SESSION_TOKEN="$SESSION_TOKEN"

aws sts get-caller-identity


