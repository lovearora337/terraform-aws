🚀 Project Overview
bash
Copy
Edit
terraform-aws-ecs/
├── main.tf               # Root config (calls module, import block, data sources)
├── variables.tf          # Variables for root module
├── outputs.tf            # Outputs from root module
└── modules/
    └── ecs-cluster/      # ECS cluster module
        ├── main.tf       # ECS cluster + service + task def resources
        ├── variables.tf
        └── outputs.tf
Step 1: Create the module modules/ecs-cluster/main.tf
hcl
Copy
Edit
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.task_family
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      essential = true
      portMappings = [{
        containerPort = var.container_port
        protocol      = "tcp"
      }]
    }
  ])

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.this]
}
Step 2: Module variables (modules/ecs-cluster/variables.tf)
hcl
Copy
Edit
variable "cluster_name" {
  type = string
}

variable "task_family" {
  type = string
}

variable "cpu" {
  type = string
}

variable "memory" {
  type = string
}

variable "container_name" {
  type = string
}

variable "container_image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "service_name" {
  type = string
}

variable "desired_count" {
  type = number
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}
Step 3: Module outputs (modules/ecs-cluster/outputs.tf)
hcl
Copy
Edit
output "cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "service_name" {
  value = aws_ecs_service.this.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}
Step 4: Root main.tf with data sources, import block, and module call
hcl
Copy
Edit
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Import existing ECS cluster (if exists)
import {
  id = "existing-ecs-cluster-name"
  to = aws_ecs_cluster.existing
}

# Data source: get default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source: get subnets from default VPC
data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data source: get security group (e.g., default SG in default VPC)
data "aws_security_group" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "group-name"
    values = ["default"]
  }
}

module "ecs" {
  source = "./modules/ecs-cluster"

  cluster_name       = "my-ecs-cluster"
  task_family        = "my-task-family"
  cpu                = "256"
  memory             = "512"
  container_name     = "my-app"
  container_image    = "nginx:latest"
  container_port     = 80
  execution_role_arn = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole" # Replace with your role ARN
  task_role_arn      = "arn:aws:iam::123456789012:role/ecsTaskRole"          # Replace with your role ARN
  service_name       = "my-ecs-service"
  desired_count      = 1
  subnet_ids         = data.aws_subnets.default_vpc_subnets.ids
  security_group_ids = [data.aws_security_group.default.id]
}
Step 5: variables.tf in root (optional)
hcl
Copy
Edit
# Define root variables here if needed, or hardcode in main.tf
Step 6: outputs.tf in root (optional)
hcl
Copy
Edit
output "ecs_cluster_id" {
  value = module.ecs.cluster_id
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "ecs_task_definition_arn" {
  value = module.ecs.task_definition_arn
}
Step 7: Usage
bash
Copy
Edit
terraform init

terraform plan

terraform apply -auto-approve
Bonus Tips
Import Block helps bring existing ECS cluster into Terraform management.

Use data sources to dynamically pick networking details so the config works across accounts.

Modularization makes your ECS infra reusable for multiple environments/projects.

You can extend the module to add ALB integration, auto-scaling, CloudWatch, etc.
