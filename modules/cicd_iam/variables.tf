# modules/cicd_iam/variables.tf

variable "project_name" {
  description = "The name of the project (e.g., 'containerized-apps-infra')."
  type        = string
}

variable "gitlab_project_path" {
  description = "The path of your GitLab project (e.g., 'aws-homelab1/internet-noise-visualizer')."
  type        = string
}

variable "ecr_repository_arn" {
  description = "The ARN of the ECR repository to grant push access to."
  type        = string
}

variable "ecs_service_arn" {
  description = "The ARN of the ECS service to grant update access to."
  type        = string
}

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster."
  type        = string
}
