# modules/data/outputs.tf

output "db_instance_endpoint" {
  description = "The connection endpoint (hostname) for the RDS instance."
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "The port for the RDS instance."
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "The name of the database created in the RDS instance."
  value       = aws_db_instance.main.db_name
}

output "db_user" {
  description = "The master username for the RDS database."
  value       = aws_db_instance.main.username
}

output "db_secret_arn" {
  description = "The ARN of the Secrets Manager secret holding the DB password."
  value       = aws_secretsmanager_secret.db_password.arn
}

output "quarantine_bucket_id" {
  description = "The ID (name) of the secure S3 bucket for PII quarantine."
  value       = aws_s3_bucket.quarantine.id
}

output "quarantine_bucket_arn" {
  description = "The ARN of the secure S3 bucket for PII quarantine."
  value       = aws_s3_bucket.quarantine.arn
}
