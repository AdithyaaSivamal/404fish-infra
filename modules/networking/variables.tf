
variable "aws_region" {
  description = "The AWS region where resources will be created."
  type        = string
}

variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

