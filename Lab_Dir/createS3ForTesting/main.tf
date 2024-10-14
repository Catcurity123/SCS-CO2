terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "cloud_user"
  region  = "us-east-1"
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "test-bucket-for-labbings"
  force_destroy = false
}
