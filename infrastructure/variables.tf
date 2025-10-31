# infrastructure/variables.tf

variable "aws_region" {
  description = "The AWS region where the infrastructure will be deployed."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "The base name for the project (e.g., 'app-infra'). Will be prefixed with env."
  type        = string
}

variable "db_password" {
  description = "The password for the RDS database master user."
  type        = string
  sensitive   = true
}

variable "budget_amount_usd" {
  description = "The monthly budget amount in USD."
  type        = number
}

variable "alert_email" {
  description = "The email address for budget alerts."
  type        = string
}

variable "gitlab_project_path" {
  description = "The path of your GitLab project (e.g., 'aws-homelab1/internet-noise-visualizer')."
  type        = string
}

variable "domain_name" {
  description = "The root domain name (e.g., 404fish.dev)"
  type        = string
}

variable "route53_zone_id" {
  description = "The ID of the permanent Route 53 Hosted Zone"
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ARN of the permanent SSL certificate in us-east-1"
  type        = string
}
