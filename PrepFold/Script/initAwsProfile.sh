#!/bin/bash

# Prompt for user input
read -p "Enter AWS Access Key ID: " aws_access_key_id
read -s -p "Enter AWS Secret Access Key: " aws_secret_access_key
echo
read -p "Enter default region (e.g., us-east-1): " aws_region
read -p "Enter output format (json, yaml, text, table): " aws_output
read -p "Enter a profile name: " aws_profile

# Configure AWS CLI profile
aws configure set aws_access_key_id "$aws_access_key_id" --profile "$aws_profile"
aws configure set aws_secret_access_key "$aws_secret_access_key" --profile "$aws_profile"
aws configure set region "$aws_region" --profile "$aws_profile"
aws configure set output "$aws_output" --profile "$aws_profile"

# Export AWS_PROFILE
export AWS_PROFILE="$aws_profile"
echo "Exported AWS_PROFILE=$AWS_PROFILE"

# Test the setup
echo "Testing credentials with aws sts get-caller-identity..."
aws sts get-caller-identity
