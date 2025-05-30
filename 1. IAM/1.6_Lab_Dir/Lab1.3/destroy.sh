#!/bin/bash

cd st3_creator_finalize
terraform destroy -auto-approve
cd ..

cd st2_accessor_init
terraform destroy -auto-approve
cd ..

cd st1_creator_init
terraform destroy -auto-approve
cd ..

echo "Cleanup complete."
