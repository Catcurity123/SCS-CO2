terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random",
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile = "lab_account"
  region  = "us-east-1"
}

resource "random_id" "suffix" { byte_length = 4 }
