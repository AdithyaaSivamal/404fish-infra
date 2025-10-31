terraform {
  required_version = ">= 1.1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  description = "The AWS region to deploy this sensor to (e.g., 'us-east-1')."
  type        = string
}

provider "aws" {
  region = var.aws_region
}

