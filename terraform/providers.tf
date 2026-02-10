# ==============================================================================
# Terraform Provider Configuration
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
#
# Provider "aws" cho phep Terraform giao tiep voi AWS API.
# "archive" dung de dong goi Lambda source code thanh .zip truoc khi upload.
# ==============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # --------------------------------------------------
  # Remote State Backend (uncomment khi production)
  # Doc: https://developer.hashicorp.com/terraform/language/backend/s3
  # --------------------------------------------------
  # backend "s3" {
  #   bucket         = "coffee-shop-tf-state"
  #   key            = "part1/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "CoffeeShop"
      ManagedBy = "Terraform"
    }
  }
}
