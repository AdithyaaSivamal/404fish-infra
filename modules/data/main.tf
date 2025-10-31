
# Creates a random string to ensure the S3 bucket name is globally unique.
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Defines a group of private subnets where the RDS instance can be placed.
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# PostgreSQL RDS database instance.
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-db"
  allocated_storage      = 10
  instance_class         = var.db_instance_class
  engine                 = "postgres"
  engine_version         = "16.6"
  username               = "masteruser"
  password               = var.db_password
  db_name                = "${replace(var.project_name, "-", "")}db"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = false
  skip_final_snapshot    = var.skip_snapshot
  monitoring_interval    = 0
}

# Creates a secret in AWS Secrets Manager to store the database password.
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}-db-password"
}

# Creates the first version of the secret with the actual password value.
resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

# --- Secure S3 Bucket for PII Quarantine ---

# Creates a dedicated KMS key for encrypting the quarantine bucket.
resource "aws_kms_key" "quarantine_key" {
  description             = "KMS key for the secure PII quarantine S3 bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = {
    Name = "${var.project_name}-quarantine-key"
  }
}

# Provisions the S3 bucket for quarantining PII-infected files.
resource "aws_s3_bucket" "quarantine" {
  bucket = "${var.project_name}-quarantine-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.project_name}-quarantine-bucket"
  }
}

# Blocks all public access to the quarantine bucket.
resource "aws_s3_bucket_public_access_block" "quarantine_public_access" {
  bucket = aws_s3_bucket.quarantine.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enforces server-side encryption using the dedicated KMS key.
resource "aws_s3_bucket_server_side_encryption_configuration" "quarantine_encryption" {
  bucket = aws_s3_bucket.quarantine.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.quarantine_key.arn
    }
  }
}

# Applies a bucket policy to enforce encryption on all uploads.
resource "aws_s3_bucket_policy" "quarantine_policy" {
  bucket = aws_s3_bucket.quarantine.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "EnforceKMSEncryption",
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.quarantine.arn}/*",
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}


