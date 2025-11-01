provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "sctp-ce11-tfstate"
    key    = "luqman-s3-tf-cicd.tfstate" #Change this
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }

  required_version = ">= 1.0.0"
}

data "aws_caller_identity" "current" {}

locals {
  prefix = split("/", data.aws_caller_identity.current.arn)[1]
  account_id  = data.aws_caller_identity.current.account_id

}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 6.7.0"

  cluster_name = "${local.prefix}-ecs"

  services = {
    luqman-ce11-task-def = { #task definition and service name -> #Change
      cpu    = 512
      memory = 1024
      container_definitions = {
        luqman-ce11-container = { #container name -> Change
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/luqman-ce11-ecr:latest"
          port_mappings = [
            {
              containerPort = 8080
              protocol      = "tcp"
            }
          ]
        }
      }
      assign_public_ip                   = true
      deployment_minimum_healthy_percent = 100
      subnet_ids                   = ["subnet-07e0e205fee5e098c","subnet-0f1e7281dca071052"] #List of subnet IDs to use for your tasks
      security_group_ids           = ["sg-076a15136e8e18423"] #Create a SG resource and pass it here
    }
  }
}

