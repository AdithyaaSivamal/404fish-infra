
# Creates a random ID to append to the S3 bucket name to ensure it's globally unique.
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Provisions the S3 bucket that will store all CloudTrail logs.
resource "aws_s3_bucket" "log_bucket" {
  bucket        = "${var.project_name}-log-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true
  tags = {
    Name = "${var.project_name}-log-bucket"
  }
}

# Enforces that the S3 log bucket is not publicly accessible.
resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Get info about the current AWS partition (e.g., "aws", "aws-cn")
data "aws_partition" "current" {}

# Get info about the current AWS account ID
data "aws_caller_identity" "current" {}

# Policy document that allows CloudTrail to write to the S3 bucket
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid = "AWSCloudTrailAclCheck"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.log_bucket.arn]
  }

  statement {
    sid = "AWSCloudTrailWrite"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.log_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}


# Provisions the CloudTrail service to log all management events in the account.
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.log_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  tags = {
    Name = "${var.project_name}-trail"
  }

  depends_on = [aws_s3_bucket_policy.log_bucket_policy]
}


