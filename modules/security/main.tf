# modules/security/main.tf

# --- Security Groups ---

# Security Group for the Application Load Balancer (ALB)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Controls access to the Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP inbound (will be for redirect)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# Security Group for the ECS Fargate services (Application Tier)
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Controls access to the ECS Fargate services"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB on the application port"
    from_port       = var.app_port # 8000
    to_port         = var.app_port # 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Only allows traffic from the ALB SG
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allows ECS tasks to reach internet (via NAT) and RDS
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# Security Group for the RDS Database instance (Data Tier)
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Controls access to the RDS database instance"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ECS services"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id] # Only allows traffic from the ECS SG
  }

  egress {
    description = "Allow all outbound traffic (within VPC)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}
