#!/bin/bash

# Define the IAM username
username="cloud_user"

# Fetch the list of attached policies
policy_arns=$(aws iam list-attached-user-policies --user-name "$username" --query 'AttachedPolicies[*].PolicyArn' --output text)

# Loop through each policy ARN
for policy_arn in $policy_arns; do
  # Get the policy's default version ID
  version_id=$(aws iam get-policy --policy-arn "$policy_arn" --query 'Policy.DefaultVersionId' --output text)

  echo "Policy ARN: $policy_arn"
  echo "Version ID: $version_id"
  echo "---------------------------"
  
  # Get the content of the policy
  aws iam get-policy-version --policy-arn "$policy_arn" --version-id "$version_id" --query 'PolicyVersion.Document' --output json

  echo ""
done
