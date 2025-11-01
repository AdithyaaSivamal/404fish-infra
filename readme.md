



 [![pipeline status](https://gitlab.com/aws-homelab1/internet-noise-visualizer/badges/main/pipeline.svg)](https://gitlab.com/aws-homelab1/internet-noise-visualizer/-/commits/main)


# 🌐 Internet Background Noise Visualizer (Infrastructure)

> This repository contains all the Infrastructure as Code (IaC) for a multi-region, high-availability threat intelligence dashboard. This project is a comprehensive demonstration of end-to-end cloud engineering, security, and DevSecOps principles.

The application code that runs on this infrastructure is in a separate repository:
[https://github.com/AdithyaaSivamal/404fish]

-----

### Table of Contents

  * [Architecture Overview](#-architecture-overview)
  * [Core Technologies](#-core-technologies)
  * [Repository Structure](#-repository-structure)
  * [Deployment Guide](#-deployment-guide)
  * [Documentation](#-documentation)

-----

## 🏛️ Architecture Overview

This project uses a **"Hub and Spoke"** architecture to collect and process data.

  * **Hub (Main App Stack):** A primary AWS region (`ap-southeast-1`) that hosts the core application. This includes the ALB, the ECS Fargate cluster (running the FastAPI app), and the central RDS PostgreSQL database.
  * **Spokes (Sensor Stacks):** Lightweight, independent stacks in other AWS regions (e.g., `us-east-1`). Each spoke deploys a "decoy sensor" (a firewalled EC2 instance) and a VPC Flow Log, which feeds data back to the central hub application.

This multi-region design provides a more accurate, less-biased view of global internet scanner traffic.

```mermaid
graph TD
    %% 1. Style Definitions
    classDef vpc fill:#FFF3E0,stroke:#FF9800,stroke-width:2px
    classDef subnet fill:#E3F2FD,stroke:#2196F3,stroke-width:1px
    classDef security fill:#FFEBEE,stroke:#F44336,stroke-width:1px
    classDef pipeline fill:#E8F5E9,stroke:#4CAF50,stroke-width:1px
    classDef developer fill:#ede7f6,stroke:#673ab7,stroke-width:1px
    classDef user fill:#e0f7fa,stroke:#0097a7,stroke-width:1px
    classDef aws fill:#232F3E,stroke:#FF9900,color:#fff,stroke-width:2px
    classDef monitor fill:#FDFEFE,stroke:#5D6D7E,stroke-width:1px
    classDef permanent fill:#E0F2F1,stroke:#00796B,stroke-width:2px,stroke-dasharray: 5 5
    classDef spoke fill:#FFF9C4,stroke:#FBC02D,stroke-width:1px

    %% 2. Actors & CI/CD
    subgraph "Developer & CI/CD Workflow"
        Dev["👨‍💻<br><b>Developer</b>"]:::developer
        AppRepo["💻<br><b>Application Repo</b><br>(github.com)"]:::pipeline
        InfraRepo["📄<br><b>Infrastructure Repo</b><br>(github.com)"]:::pipeline
        GitLab["<br><b>GitLab CI/CD</b>"]:::pipeline

        Dev -- "git push" --> AppRepo
        Dev -- "terraform apply" --> InfraRepo
        AppRepo -- "Triggers Pipeline" --> GitLab
    end

    subgraph "GitLab CI/CD Pipeline"
        direction LR
        GitLab --> OIDC["fa:fa-id-card<br><b>IAM OIDC Auth</b><br>AssumeRole"]:::aws
        
        subgraph "Application Pipeline"
            OIDC --> A2[Build Docker Image]:::pipeline
            A2 --> A3{"Scan Image<br><b>Trivy</b>"}:::security
            A3 --> A4[Push to ECR]:::pipeline
            A4 --> A6["Deploy to ECS<br>(Update Service)"]:::pipeline
        end
    end
    
    subgraph "AWS Cloud"
        direction TB

        %% Permanent DNS Stack
        subgraph DNS ["Permanent DNS Stack (infrastructure-dns)"]
            style DNS permanent
            R53["fa:fa-globe<br><b>Route 53</b><br>404fish.dev"]
            ACM["fa:fa-lock<br><b>ACM Certificate</b><br>(*.404fish.dev)<br>ap-southeast-1"]
        end
    
        %% User & Scanner Ingress
        User["👤<br><b>End User</b>"]:::user -- "[https://dev.404fish.dev](https://dev.404fish.dev)" --> R53
        Scanner["🤖<br><b>Scanner/Bot</b>"]

        %% Hub VPC
        subgraph VPC ["Hub VPC (infrastructure/dev) - ap-southeast-1"]
            style VPC vpc
            
            ALB["<br><b>Application Load Balancer</b><br>(HTTPS: 443)"]:::aws
            
            subgraph PubSub ["Public Subnets"]
                style PubSub subnet
                HubSensor["fa:fa-eye<br><b>Decoy Sensor 1</b><br>(EC2 Instance)"]
                NAT[NAT Gateway]
            end

            subgraph PrivSub ["Private Subnets"]
                style PrivSub subnet
                ECS["fa:fa-box<br><b>ECS on Fargate</b><br>FastAPI Application"]
                RDS["fa:fa-database<br><b>RDS PostgreSQL</b>"]
            end
            
            HubLogs["fa:fa-cloud-watch<br><b>CloudWatch Logs</b><br>(ap-se-1)"]:::monitor
        end
        
        %% Spoke VPC
        subgraph SpokeVPC ["Spoke VPC (infrastructure-sensor-region) - us-east-1"]
            style SpokeVPC spoke
            SpokeSensor["fa:fa-eye<br><b>Decoy Sensor 2</b><br>(EC2 Instance)"]
            SpokeLogs["fa:fa-cloud-watch<br><b>CloudWatch Logs</b><br>(us-east-1)"]:::monitor
        end

        %% Shared Services
        subgraph "Shared Services"
           ECR["📦<br>Elastic Container<br>Registry"]:::aws
           SecretsManager["🔑<br>Secrets Manager"]:::security
        end

        %% --- Data & Traffic Flows ---
        R53 -- "A Record ('dev')" --> ALB
        ALB -- "Uses Cert" --> ACM
        ALB -- "Forwards to" --> ECS
        ECS -- "R/W Data" --> RDS
        ECS -- "Get Secrets" --> SecretsManager
        ECS -- "Outbound" --> NAT
        
        %% Data Collection
        Scanner --> HubSensor
        Scanner --> SpokeSensor
        HubSensor -- "VPC Flow Logs" --> HubLogs
        SpokeSensor -- "VPC Flow Logs" --> SpokeLogs
        ECS -- "Polls (Multi-Region)" --> HubLogs
        ECS -- "Polls (Multi-Region)" --> SpokeLogs
        
        %% CI/CD Connections
        InfraRepo -- "Provisions" --> VPC
        InfraRepo -- "Provisions" --> SpokeVPC
        InfraRepo -- "Provisions" --> DNS
        A6 -- "Updates" --> ECS
        A4 -- "Pushes to" --> ECR
        ECS -- "Pulls Image" --> ECR
    end

```


-----

## 💻 Core Technologies

This project is built entirely with **Terraform** and **AWS**.

| Category | Technologies Used |
| :--- | :--- |
| **IaC** | Terraform (Workspaces, Modules) |
| **Cloud Provider** | Amazon Web Services (AWS) |
| **Compute** | ECS on Fargate, EC2 (for decoy sensors) |
| **Database** | RDS PostgreSQL |
| **Networking** | VPC, Public/Private Subnets, NAT Gateway, Security Groups, Route 53 |
| **Security** | IAM (Roles, Policies), ACM (SSL Certificates), Secrets Manager |
| **Logging** | CloudWatch (for Flow Logs), CloudTrail (for auditing) |

-----

## 📁 Repository Structure

This repository contains multiple, independent Terraform projects:

  * `infrastructure-dns/`
      * **Permanent Stack.** Manages the Route 53 Hosted Zone and the global ACM SSL Certificate. Run this once and then leave it alone.
  * `infrastructure-sensor-region/`
      * **Ephemeral Spoke.** A template for deploying new decoy sensors in remote regions.
  * `infrastructure/`
      * **Ephemeral Hub.** The main application stack, managed with Terraform Workspaces.

-----

## 🚀 Deployment Guide

The main `infrastructure/` directory uses Terraform Workspaces to manage `dev` and `prod` environments.

### To Deploy the `dev` Environment:

```bash
# 1. Navigate to the main infrastructure directory
cd infrastructure/

# 2. Initialize Terraform
terraform init

# 3. Select the 'dev' workspace (or create it)
terraform workspace select dev
# (if it doesn't exist, run: terraform workspace new dev)

# 4. Plan the deployment
terraform plan -var-file="dev.tfvars"

# 5. Apply the deployment
terraform apply -var-file="dev.tfvars"
```

### To Destroy the `dev` Environment:

```bash
cd infrastructure/
terraform workspace select dev
terraform destroy -var-file="dev.tfvars"
```

-----

## 📚 Documentation

For a complete breakdown of the architecture, security controls, and deployment strategy, see the detailed documentation:

  * **[Architecture Deep Dive](/docs/architecture_deepdive.md)**
  * **[CI/CD Pipeline Breakdown (Coming Soon)]()**
  * **[Security & Best Practices (Coming Soon)]()**
