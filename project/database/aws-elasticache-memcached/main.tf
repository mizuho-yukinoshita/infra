provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        TerraformKey = "database/aws-elasticache-memcached"
        SystemName   = var.system_name
        Environment  = var.env
        ManagedBy    = "Terraform"
      },
      var.default_tags
    )
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
  cluster_id     = "${var.system_name}-${var.env}-memcached"
  engine         = "memcached"
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = 11211

  num_cache_nodes      = var.num_cache_nodes
  az_mode              = var.az_mode
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = var.security_group_ids
  parameter_group_name = var.parameter_group_name

  transit_encryption_enabled = var.transit_encryption_enabled

  maintenance_window = var.maintenance_window
}
