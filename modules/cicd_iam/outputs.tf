# modules/cicd_iam/outputs.tf

output "cicd_role_arn" {
  description = "The ARN of the IAM role for the GitLab CI/CD pipeline."
  value       = aws_iam_role.gitlab_cicd_role.arn
}
