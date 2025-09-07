#!/bin/bash

# Ask for profile name

echo "🔹 Checking current AWS identity (default)..."
aws sts get-caller-identity --output json 2>/dev/null || echo "No default AWS identity is currently set."

echo
read -p "Enter AWS profile name: " PROFILE_NAME
read -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -s -p "Enter AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo
read -p "Enter AWS Region (default: us-east-1): " AWS_DEFAULT_REGION

# Set default region if not provided
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}

# Configure the provided profile
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$PROFILE_NAME"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile "$PROFILE_NAME"
aws configure set region "$AWS_DEFAULT_REGION" --profile "$PROFILE_NAME"

echo
echo "✅ Credentials saved under profile: $PROFILE_NAME"
echo "🔹 Verifying AWS identity for profile $PROFILE_NAME..."
aws sts get-caller-identity --profile "$PROFILE_NAME" --output json 2>/dev/null || echo "Failed to authenticate with provided credentials."
