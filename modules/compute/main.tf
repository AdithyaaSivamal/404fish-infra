# modules/compute/main.tf
# Defines the compute layer: ECR Repo, ALB, ECS Cluster, Task Definition, Service, and IAM Roles.

# --- ECR (Elastic Container Registry) ---

resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-app-repo"
  }
}


# --- Application Load Balancer (ALB) ---

resource "aws_lb" "main" {
  name               = "${var.project_name}-lb" # Shortened name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets

  tags = {
    Name = "${var.project_name}-lb"
  }
}

resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-tg"
  port        = 8000 # App runs on 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/" # FastAPI serves the root path
    protocol            = "HTTP"
    port                = "traffic-port" # port 8000
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}

#resource "aws_lb_listener" "http" {
#  load_balancer_arn = aws_lb.main.arn
#  port              = "80" # ALB listens on 80
#  protocol          = "HTTP"
#
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.main.arn # Forwards to TG on port 8000
#  }
#}

# HTTP listener on port 80 to permanently redirect to HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301" # Permanent Redirect
    }
  }
}

# HTTPS listener on port 443 that forwards to your application
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn # Use the certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}


# --- ECS (Elastic Container Service) ---

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# --- IAM Roles for ECS ---

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# --- IAM Policy for Reading Secrets ---
resource "aws_iam_policy" "read_secret_policy" {
  name        = "${var.project_name}-read-secret-policy"
  description = "Allows reading the DB secret"

  depends_on = [aws_iam_role.ecs_task_role]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = var.db_secret_arn
      }
    ]
  })
}

# Attach secret policy to the Task Role
resource "aws_iam_role_policy_attachment" "ecs_task_read_secret_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.read_secret_policy.arn
  depends_on = [aws_iam_policy.read_secret_policy, aws_iam_role.ecs_task_role]
}

# Attach secret policy to the Execution Role (for 'secrets' block)
resource "aws_iam_role_policy_attachment" "ecs_execution_read_secret_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.read_secret_policy.arn
  depends_on = [aws_iam_policy.read_secret_policy, aws_iam_role.ecs_task_execution_role]
}


# --- IAM Policy for Reading Flow Logs ---
resource "aws_iam_policy" "read_flow_logs_policy" {
  name        = "${var.project_name}-read-flow-logs-policy"
  description = "Allows ECS Task Role to read decoy VPC Flow Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadDecoyFlowLogs"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        # We use a wildcard to match all log groups for this project,
        # in any region, plus all log streams inside them.
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/vpc/containerized-apps-infra-*:*",
          "arn:aws:logs:*:*:log-group:/aws/vpc/containerized-apps-infra-*:log-stream:*"
        ]
      }
    ]
  })
}

# Attach the new log policy to the Task Role
resource "aws_iam_role_policy_attachment" "ecs_task_read_logs_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.read_flow_logs_policy.arn

  depends_on = [
    aws_iam_policy.read_flow_logs_policy,
    aws_iam_role.ecs_task_role
  ]
}


# --- Artificial Delay ---
resource "time_sleep" "iam_propagation_delay" {
  create_duration = "30s"
  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_policy_attachment,
    aws_iam_role_policy_attachment.ecs_task_read_secret_attachment,
    aws_iam_role_policy_attachment.ecs_execution_read_secret_attachment,
    aws_iam_role_policy_attachment.ecs_task_read_logs_attachment
  ]
}

# --- CloudWatch Log Group for ECS Task ---
resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name              = "/ecs/${var.project_name}-task"
  retention_in_days = 7
  tags = {
    Name = "${var.project_name}-ecs-task-logs"
  }
}


# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  depends_on = [
    time_sleep.iam_propagation_delay,
    aws_cloudwatch_log_group.ecs_task_logs
  ]

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-container"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = var.db_secret_arn
        }
      ]
      environment = [
        { name = "DB_HOST", value = var.db_endpoint },
        { name = "DB_PORT", value = tostring(var.db_port) },
        { name = "DB_USER", value = var.db_user },
        { name = "DB_NAME", value = var.db_name },
        { name = "CW_LOG_GROUPS_JSON", value = var.cw_log_groups_json }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_task_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-task-def"
  }
}

# --- ECS Service ---
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.ecs_task_count # Use variable
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "${var.project_name}-container"
    container_port   = 8000
  }

  force_new_deployment = true

  depends_on = [aws_lb_listener.https]

  tags = {
    Name = "${var.project_name}-service"
  }
}
