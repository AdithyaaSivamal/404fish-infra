
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The hosted zone ID of the ALB (for Route 53 Alias records)."
  value       = aws_lb.main.zone_id
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository for the application image."
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  description = "The ARN of the ECR repository."
  value       = aws_ecr_repository.app.arn
}

output "ecs_service_arn" {
  description = "The ARN of the ECS service."
  value       = aws_ecs_service.main.id # .id is the ARN for ecs_service
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster."
  value       = aws_ecs_cluster.main.arn
}
