//----------------------
# PROVIDER SETUP
# ----------------------
terraform {
  backend "s3" {
    bucket         = "url-shortener-tf-state-bucket"
    key            = "url-shortener/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40" # Specify a modern version that supports CloudWatch Metric Filters
    }
  }
}

provider "aws" {
  region = "us-east-1"
}