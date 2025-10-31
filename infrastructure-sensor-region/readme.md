Terraform - Sensor Region Deployment


Initialize Terraform:

terraform init


Deploy to a new region (e.g., us-east-1):

terraform apply -var="aws_region=us-east-1" -var="project_name=containerized-apps-infra"


Deploy to another region (e.g., eu-west-1):

terraform apply -var="aws_region=eu-west-1" -var="project_name=containerized-apps-infra"


Note the decoy_flow_log_group_arn output. You must add this ARN to the environment variables of the central dashboard application.
