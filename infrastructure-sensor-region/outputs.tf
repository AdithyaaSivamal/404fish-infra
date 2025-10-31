output "decoy_flow_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for this sensor."
  value       = module.networking.decoy_flow_log_group_arn
}

output "decoy_sensor_public_ip" {
  description = "The public IP of the decoy sensor in this region."
  value       = aws_instance.decoy_sensor.public_ip
}

