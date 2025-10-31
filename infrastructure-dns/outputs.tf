output "route53_zone_id" {
  description = "The ID of the hosted zone (needed by your dev/prod stacks)."
  value       = aws_route53_zone.main.zone_id
}

output "acm_certificate_arn" {
  description = "The ARN of the SSL certificate (needed by your dev/prod stacks)."
  value       = aws_acm_certificate.main.arn
}

output "name_servers" {
  description = "The AWS Name Servers for your domain. Manually set these in your domain registrar."
  value       = aws_route53_zone.main.name_servers
}
