# This file declares the input variables that the compute module expects.

variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "public_subnets" {
  description = "A list of public subnet IDs for the ALB."
  type        = list(string)
}

variable "private_subnets" {
  description = "A list of private subnet IDs for the ECS tasks."
  type        = list(string)
}

variable "alb_sg_id" {
  description = "The security group ID for the ALB."
  type        = string
}

variable "ecs_sg_id" {
  description = "The security group ID for the ECS tasks."
  type        = string
}

# CORRECTED: This is the secure way to handle credentials.
# The module now only needs the ARN of the secret.
variable "db_secret_arn" {
  description = "The ARN of the database password secret in Secrets Manager."
  type        = string
  sensitive   = true
}

variable "db_endpoint" {
  description = "The endpoint of the RDS database."
  type        = string
}

variable "db_port" {
  description = "The port of the RDS database."
  type        = string # The container environment expects a string.
}

variable "db_name" {
  description = "The name of the database."
  type        = string
}

#variable "app_image" {
#  description = "The Docker image URL for the application."
#  type        = string
#  default     = "public.ecr.aws/nginx/nginx:latest" # Using a placeholder for now.
#}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "db_user" {
  description = "The username for the database."
  type        = string
  default     = "admin" # Default value, can be overridden.
}

#variable "decoy_flow_log_group_name" {
#  description = "The name of the CloudWatch Log Group for the decoy's flow logs."
#  type        = string
#}

variable "cw_log_groups_json" {
  description = "A JSON string listing the log groups to poll."
  type        = string
  default     = "[]"
}

variable "decoy_flow_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for the decoy's flow logs."
  type        = string
}

variable "ecs_task_count" {
  description = "The desired number of ECS tasks to run for the service."
  type        = number
  default     = 1
}

variable "acm_certificate_arn" {
  description = "The ARN of the SSL certificate to attach to the ALB."
  type        = string
}
