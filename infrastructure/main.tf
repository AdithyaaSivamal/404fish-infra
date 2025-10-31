# infrastructure/main.tf

locals {
  env_config = {
    dev = {
      instance_type    = "t3.nano"
      db_instance      = "db.t3.micro"
      ecs_task_count   = 1
      project_suffix   = "dev"
      db_skip_snapshot = true
    }
    prod = {
      instance_type    = "t3.micro"
      db_instance      = "db.t3.small"
      ecs_task_count   = 2
      project_suffix   = "prod"
      db_skip_snapshot = false
    }
  }

  env              = terraform.workspace == "prod" ? local.env_config.prod : local.env_config.dev
  project_name_env = "${var.project_name}-${local.env.project_suffix}"
}

# --- 1. Networking Module ---
module "networking" {
  source = "../modules/networking"

  aws_region   = var.aws_region
  project_name = local.project_name_env
  vpc_cidr     = "10.0.0.0/16"
}

# --- 2. Security Module ---
module "security" {
  source = "../modules/security"

  project_name = local.project_name_env
  vpc_id       = module.networking.vpc_id
  app_port     = 8000
}

# --- 3. Data Module ---
module "data" {
  source = "../modules/data"

  project_name      = local.project_name_env
  private_subnets   = module.networking.private_subnets
  rds_sg_id         = module.security.rds_sg_id
  db_password       = var.db_password
  db_instance_class = local.env.db_instance
  skip_snapshot     = local.env.db_skip_snapshot
}

# --- 4. Compute Module ---
module "compute" {
  source = "../modules/compute"

  project_name    = local.project_name_env
  aws_region      = var.aws_region
  vpc_id          = module.networking.vpc_id
  public_subnets  = module.networking.public_subnets
  private_subnets = module.networking.private_subnets
  alb_sg_id       = module.security.alb_sg_id
  ecs_sg_id       = module.security.ecs_sg_id
  db_secret_arn   = module.data.db_secret_arn
  db_endpoint     = module.data.db_instance_endpoint
  db_port         = module.data.db_instance_port
  db_name         = module.data.db_name
  db_user         = module.data.db_user
  ecs_task_count  = local.env.ecs_task_count

  decoy_flow_log_group_arn = module.networking.decoy_flow_log_group_arn

  cw_log_groups_json = jsonencode([
    {
      region = var.aws_region,
      name   = module.networking.decoy_flow_log_group_name
    },
    {
      region = "us-east-1",
      name   = "/aws/vpc/containerized-apps-infra-us-east-1-decoy-flow-logs"
    }
  ])

  # Pass the certificate ARN to the compute module
  acm_certificate_arn = var.acm_certificate_arn
}

# --- 5. Logging Module ---
module "logging" {
  source       = "../modules/logging"
  project_name = local.project_name_env
}

# --- 6. Cost Management Module ---
module "cost_management" {
  source            = "../modules/cost_management"
  project_name      = local.project_name_env
  budget_amount_usd = var.budget_amount_usd
  alert_email       = var.alert_email
}

# --- 7. CI/CD IAM Module ---
module "cicd_iam" {
  source = "../modules/cicd_iam"

  project_name        = local.project_name_env
  gitlab_project_path = var.gitlab_project_path
  ecr_repository_arn  = module.compute.ecr_repository_arn
  ecs_service_arn     = module.compute.ecs_service_arn
  ecs_cluster_arn     = module.compute.ecs_cluster_arn
}

# --- Decoy Sensor Resources (EC2 Instance & Security Group) ---
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "decoy_sensor_sg" {
  name        = "${local.project_name_env}-decoy-sg"
  description = "Allow specific inbound port for decoy sensor"
  vpc_id      = module.networking.vpc_id

  ingress {
    description = "Allow inbound on decoy port (e.g., Telnet 23)"
    from_port   = 23
    to_port     = 23
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name_env}-decoy-sg"
  }
}

resource "aws_instance" "decoy_sensor" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = local.env.instance_type
  subnet_id                   = module.networking.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.decoy_sensor_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nc
              # Listen on port 23
              nc -lk 23 > /dev/null
              EOF

  tags = {
    Name = "${local.project_name_env}-decoy-sensor"
  }
}

# --- VPC Flow Log for the Decoy Sensor's Network Interface ---
resource "aws_flow_log" "decoy_eni_flow_log" {
  log_destination_type = "cloud-watch-logs"
  log_destination      = module.networking.decoy_flow_log_group_arn
  traffic_type         = "ALL"
  eni_id               = aws_instance.decoy_sensor.primary_network_interface_id
  iam_role_arn         = module.networking.flow_log_role_arn

  tags = {
    Name = "${local.project_name_env}-decoy-flow-log"
  }

  depends_on = [module.networking]
}

# --- 8. Create the DNS "A" Record ---
resource "aws_route53_record" "app" {
  zone_id = var.route53_zone_id
  name    = "${terraform.workspace}.${var.domain_name}" # e.g., "dev.404fish.dev"
  type    = "A"

  alias {
    name                   = module.compute.alb_dns_name
    zone_id                = module.compute.alb_zone_id
    evaluate_target_health = true
  }
}



