
output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "A list of the public subnet IDs."
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnets" {
  description = "A list of the private subnet IDs."
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

# Outputs for Flow Logs
output "flow_log_role_arn" {
  description = "The ARN of the IAM role for VPC Flow Logs."
  value       = aws_iam_role.flow_log_role.arn
}

output "decoy_flow_log_group_name" {
  description = "The name of the CloudWatch Log Group for the decoy's flow logs."
  value       = aws_cloudwatch_log_group.decoy_flow_logs.name
}

# Output the ARN instead of just the name
output "decoy_flow_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for decoy flow logs."
  value       = aws_cloudwatch_log_group.decoy_flow_logs.arn
}


