#!/bin/bash

echo "Applying st1_creator_init..."
cd st1_creator_init
terraform init -upgrade
terraform apply -auto-approve
terraform output -raw creator_account_id > ../st2_accessor_init/creator_account_id.txt

cd ../st2_accessor_init

echo "Applying st2_accessor..."
terraform init -upgrade
terraform apply -auto-approve
terraform output -raw accessor_account_id > ../st3_creator_finalize/accessor_account_id.txt

cd ../st3_creator_finalize

echo "Applying st3_creator_finalize..."
terraform init -upgrade
terraform apply -auto-approve
