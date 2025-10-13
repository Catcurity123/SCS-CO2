#!/bin/bash

cd st3
terraform destroy -auto-approve
cd ..

cd st2
terraform destroy -auto-approve
cd ..

cd st1
terraform destroy -auto-approve
cd ..

echo "Cleanup complete."
