
variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
}

variable "private_subnets" {
  description = "A list of private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "rds_sg_id" {
  description = "The ID of the security group to attach to the RDS instance."
  type        = string
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
  default     = "webappdb"
}

variable "db_user" {
  description = "The master username for the database."
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true # sensitive
}

variable "db_instance_class" {
  description = "The instance class for the RDS database (e.g., db.t3.micro)."
  type        = string
  default     = "db.t3.micro"
}

variable "skip_snapshot" {
  description = "If true, skip creating a final snapshot on destroy. (Good for dev, bad for prod)"
  type        = bool
  default     = true
}
