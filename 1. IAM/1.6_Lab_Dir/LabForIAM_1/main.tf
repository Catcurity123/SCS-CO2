#### IAM Lab 1

##### Case 1 Demonstrate the use of permission policy
###### 1.1 Specify the Terraform providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

###### 1.2 Specify the SCP
provider "aws" {
  alias   = "account_A"
  profile = "CloudLab"
  region  = "us-east-1"
  #access_key              = "YOUR_ACCESS_KEY"
  #secret_key              = "YOUR_SECRET_KEY"
  /*
    assume_role {
        role_arn     = "arn:aws:iam::123456789012:role/RoleToAssume"
        session_name = "terraform"
        external_id  = "your-external-id"
    }*/
}


provider "aws" {
  alias   = "account_B"
  profile = "LabAccount"
  region  = "us-east-1"
  #access_key              = "YOUR_ACCESS_KEY"
  #secret_key              = "YOUR_SECRET_KEY"
  /*
    assume_role {
        role_arn     = "arn:aws:iam::123456789012:role/RoleToAssume"
        session_name = "terraform"
        external_id  = "your-external-id"
    }*/
}

module "iam" {
  source = "./iam"
}

module "s3" {
  source = "./s3"
}