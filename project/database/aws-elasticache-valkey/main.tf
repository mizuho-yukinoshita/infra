terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    key = "database/aws-elasticache-valkey/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.73"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      TerraformKey = "database/aws-elasticache-valkey"
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
  name        = "${var.system_name}-${var.env}-valkey-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "Subnet group for ${var.system_name} ${var.env} Valkey"
}

# ---------------------------------------------
# Valkeyクラスター
# ---------------------------------------------
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.system_name}-${var.env}-valkey"
  description          = "${var.system_name} ${var.env} Valkey Cluster"

  engine               = "valkey"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = 6379

  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = var.security_group_ids
  parameter_group_name = var.parameter_group_name

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled
  num_cache_clusters         = var.num_cache_clusters

  lifecycle {
    ignore_changes = [
      auth_token,
    ]
  }
}