terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "main_account"
  region  = "us-east-1"
}

data "aws_organizations_organization" "root" {}
locals {
  root_id = data.aws_organizations_organization.root.roots[0].id
}

locals {
  dev-ou-name = "Development"
  staging-ou-name = "Staging"
  prod-ou-name = "Production"
  manage = "Terraform"
  environment-dev = "development"
  environment-staging = "staging"
  environment-prod = "production"
  env-dev = "test-dev"
  env-staging = "test-staging"
  env-prod = "test-prod"
  organization  = "test"
}

resource "aws_organizations_organizational_unit" "test-dev" {
  name = "Test-Development"
  parent_id = local.root_id
}

resource "aws_organizations_account" "test-dev" {
  name  = "development"
  email = "admin+dangviluanwk@gmail.com"
  iam_user_access_to_billing = "ALLOW"
  role_name = "testadmin"
  parent_id = aws_organizations_organizational_unit.test-dev.id
  close_on_deletion = "true"

  tags = {
    Name = local.dev-ou-name
    ManagedBy = local.manage
    Environment = local.environment-dev
    env = local.env-dev
    organization = local.organization
  }
}

resource "aws_organizations_organizational_unit" "test-staging" {
  name = "Test-Staging"
  parent_id = local.root_id
}

resource "aws_organizations_account" "test-staging" {
  name  = "staging"
  email = "staging+dangviluanwk@gmail.com"
  iam_user_access_to_billing = "ALLOW"
  role_name = "stagingrole"
  parent_id = aws_organizations_organizational_unit.test-staging.id
  close_on_deletion = "true"

  tags = {
    Name = local.staging-ou-name
    ManagedBy = local.manage
    Environment = local.environment-staging
    env = local.env-staging
    organization = local.organization
  }
}

resource "aws_organizations_organizational_unit" "test-prod" {
  name = "Test-Production"
  parent_id = local.root_id
}

resource "aws_organizations_account" "test-prod" {
  name  = "production"
  email = "production+dangviluanwk@gmail.com"
  iam_user_access_to_billing = "ALLOW"
  role_name = "productionadmin"
  parent_id = aws_organizations_organizational_unit.test-prod.id
  close_on_deletion = "true"

  tags = {
    Name = local.prod-ou-name
    ManagedBy = local.manage
    Environment = local.environment-prod
    env = local.env-prod
    organization = local.organization
  }
}