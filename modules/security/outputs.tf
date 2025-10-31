
output "alb_sg_id" {
  description = "The ID of the Application Load Balancer security group."
  value       = aws_security_group.alb.id
}

output "ecs_sg_id" {
  description = "The ID of the ECS service security group."
  value       = aws_security_group.ecs.id
}

output "rds_sg_id" {
  description = "The ID of the RDS database security group."
  value       = aws_security_group.rds.id
}

