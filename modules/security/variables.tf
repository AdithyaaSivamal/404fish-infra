
variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the security groups will be created."
  type        = string
}

variable "app_port" {
  description = "The port the application container listens on."
  type        = number
  default     = 8000
}

variable "db_port" {
  description = "The port the RDS database listens on (e.g., 5432 for PostgreSQL)."
  type        = number
  default     = 5432
}

