#!/bin/bash

# Define an array of users
users=("user-1" "user-2" "user-3")

# Loop through each user in the array
for user in "${users[@]}"; do
  # Print the current user
  echo "Setting password for: $user"
  # Example AWS CLI command to create a login profile
  aws iam create-login-profile --user-name "$user" --password "P@sswprd1!" #--password-reset-required
done

