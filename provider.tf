terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
    external = {
      source = "hashicorp/external"
      version = "2.3.4"
    }
  }
}

provider "aws" {
    region = "eu-north-1"
    shared_credentials_files = ["/Users/jakub/.aws/credentials"]
}
