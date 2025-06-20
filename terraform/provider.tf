//----------------------
# PROVIDER SETUP
# ----------------------
provider "aws" {
  region = "us-east-1"
}


//backend block is like this

terraform {
  backend "s3" {
    bucket         = "url-shortener-tf-state-bucket"
    key            = "url-shortener/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
