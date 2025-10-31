# This configuration deploys ONLY the sensor components.

locals {
  project_name_env = "${var.project_name}-${var.aws_region}"
}

# --- 1. Networking (Lightweight) ---
module "networking" {
  source = "../modules/networking"

  aws_region   = var.aws_region
  project_name = local.project_name_env
}

# --- 2. Decoy Sensor (EC2 & SG) ---
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
  instance_type               = "t3.nano" # Keep it cheap
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

# --- 3. Flow Log ---
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

