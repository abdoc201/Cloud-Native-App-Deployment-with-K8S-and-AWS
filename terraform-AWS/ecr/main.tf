terraform {
  backend "s3" {
    bucket = "terraform-state-abdo-2001"
    key    = "ecr-terraform.tfstate"
    region = "eu-west-3"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_ecr_repository" "ecr_repo" {
  name = var.repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}