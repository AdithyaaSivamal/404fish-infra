
output "log_bucket_name" {
  description = "The name of the S3 bucket where logs are stored."
  value       = aws_s3_bucket.log_bucket.bucket
}

output "cloudtrail_arn" {
  description = "The ARN of the CloudTrail trail."
  value       = aws_cloudtrail.main.arn
}

