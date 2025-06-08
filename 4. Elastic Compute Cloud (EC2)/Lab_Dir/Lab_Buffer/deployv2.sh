#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
# This is the key to stopping the process if any check fails.
set -e

# --- Reusable function to run the standard Terraform workflow for a stage ---
run_terraform_stage() {
  local dir=$1
  local stage_name=$2

  echo "======================================================================="
  echo "=> Processing Stage: $stage_name in directory ./$dir (Automated)"
  echo "======================================================================="

  cd "$dir"

  echo "--> Initializing Terraform..."
  terraform init -upgrade -input=false

  # This is the change: Remove "-check" to auto-fix instead of stopping.
  echo "--> Formatting code (if necessary)..."
  terraform fmt

  echo "--> Validating configuration..."
  terraform validate

  # 4. Create a plan
  echo "--> Creating execution plan..."
  terraform plan -out="$plan_file"
  
  # Show the plan for user review
  echo
  echo "------------------------- PLAN PREVIEW --------------------------------"
  terraform show "$plan_file"
  echo "-----------------------------------------------------------------------"
  echo

  # 5. Ask for user approval
  read -p "Do you want to apply the plan for stage '$stage_name'? (yes/no): " approval

  if [[ "$approval" =~ ^[yY](es)?$ ]]; then
    echo "--> Applying plan..."
    terraform apply "$plan_file"
    echo "--> Stage '$stage_name' applied successfully."
  else
    echo "Approval denied. Stopping script."
    exit 1
  fi

  # Go back to the root directory
  cd ..
}

# --- Main script execution ---

# Stage 1: Creator Init
run_terraform_stage "st1" "Creator Init"
# After successful apply, get the output
echo "--> Saving output: creator_account_id"
terraform -chdir=st1 output -raw creator_account_id > st2/creator_account_id.txt

# Stage 2: Accessor
run_terraform_stage "st2" "Accessor"
# After successful apply, get the output
echo "--> Saving output: accessor_account_id"
terraform -chdir=st2 output -raw accessor_account_id > st3/accessor_account_id.txt

# Stage 3: Creator Finalize
run_terraform_stage "st3" "Creator Finalize"


echo "======================================================================="
echo "✅ All stages completed successfully!"
echo "======================================================================="