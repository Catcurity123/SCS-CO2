#!/bin/bash

echo "Applying st1_creator_init..."
cd st1
terraform init -upgrade
terraform apply -auto-approve
terraform output -raw creator_account_id > ../st2/creator_account_id.txt

cd ../st2

echo "Applying st2_accessor..."
terraform init -upgrade
terraform apply -auto-approve
terraform output -raw accessor_account_id > ../st3/accessor_account_id.txt

cd ../st3

echo "Applying st3_creator_finalize..."
terraform init -upgrade
terraform apply -auto-approve
