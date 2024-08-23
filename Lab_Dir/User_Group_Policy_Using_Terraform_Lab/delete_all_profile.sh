#!/bin/bash

# Define an array of users
users=("user-1" "user-2" "user-3")

# Loop through each user in the array
for user in "${users[@]}"; do
  # Print the current user
  echo "Deletting password for: $user"
  # Example AWS CLI command to create a login profile
  aws iam delete-login-profile --user-name "$user"
done

