terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    key = "database/aws-elasticache-memcached/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      TerraformKey = "database/aws-elasticache-memcached"
      SystemName   = var.system_name
      Environment  = var.env
      ManagedBy    = "Terraform"
    }
  }
}

# ---------------------------------------------
# サブネットグループ
# ---------------------------------------------
resource "aws_elasticache_subnet_group" "main" {
  name        = "${var.system_name}-${var.env}-memcached-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "Subnet group for ${var.system_name} ${var.env} Memcached"
}

# ---------------------------------------------
# Memcachedクラスター
# ---------------------------------------------
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.system_name}-${var.env}-memcached"
  engine               = "memcached"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = 11211

  num_cache_nodes      = var.num_cache_nodes
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = var.security_group_ids
  parameter_group_name = var.parameter_group_name
}