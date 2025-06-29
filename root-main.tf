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
