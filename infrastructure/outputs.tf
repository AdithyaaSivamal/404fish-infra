
output "application_url" {
  description = "The public HTTP URL of the application load balancer."
  value       = "http://${module.compute.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository for the application image."
  value       = module.compute.ecr_repository_url
}

output "decoy_sensor_public_ip" {
  description = "The public IP address of the decoy sensor EC2 instance."
  value       = aws_instance.decoy_sensor.public_ip
}

output "cicd_role_arn" {
  description = "The ARN of the IAM role for the GitLab CI/CD pipeline. Set this as AWS_ROLE_ARN in GitLab."
  value       = module.cicd_iam.cicd_role_arn
}

