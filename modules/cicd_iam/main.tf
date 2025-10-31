# modules/cicd_iam/main.tf

# 1. Create the OpenID Connect (OIDC) provider for gitlab.com
resource "aws_iam_openid_connect_provider" "gitlab" {
  url             = "https://gitlab.com"
  client_id_list  = ["https://gitlab.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780c34a"] # Standard GitLab thumbprint
}

# 2. Define the IAM policy that grants ECR/ECS permissions
resource "aws_iam_policy" "gitlab_cicd_policy" {
  name        = "${var.project_name}-GitLabCICDPolicy"
  description = "Grants GitLab CI/CD permissions for ECR push and ECS deploy"

  # Policy JSON. Note: We use data sources to get ARNs dynamically.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowECRAuth",
        Effect   = "Allow",
        Action   = "ecr:GetAuthorizationToken",
        Resource = "*"
      },
      {
        Sid    = "AllowECRPush",
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],
        Resource = var.ecr_repository_arn
      },
      {
        Sid      = "AllowECSUpdateService",
        Effect   = "Allow",
        Action   = "ecs:UpdateService",
        Resource = var.ecs_service_arn,
        Condition = {
          StringEquals = {
            "ecs:cluster" = var.ecs_cluster_arn
          }
        }
      }
    ]
  })
}

# 3. Define the IAM role that GitLab will assume
resource "aws_iam_role" "gitlab_cicd_role" {
  name = "${var.project_name}-GitLabCICDRole"

  # Trust policy (assume role policy)
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.gitlab.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "gitlab.com:aud" = "https://gitlab.com"
          },
          StringLike = {
            # Use the variable for the project path
            "gitlab.com:sub" = "project_path:${var.gitlab_project_path}:ref_type:*:ref:*"
          }
        }
      }
    ]
  })
}

# 4. Attach the policy to the role
resource "aws_iam_role_policy_attachment" "gitlab_cicd_attach" {
  role       = aws_iam_role.gitlab_cicd_role.name
  policy_arn = aws_iam_policy.gitlab_cicd_policy.arn
}
