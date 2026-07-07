provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        TerraformKey = "database/aws-elasticache-valkey"
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

  engine         = "valkey"
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = 6379

  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = var.security_group_ids
  parameter_group_name = var.parameter_group_name

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled
  num_cache_clusters         = var.num_cache_clusters

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  kms_key_id                 = var.kms_key_id
  auth_token                 = var.auth_token

  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window

  maintenance_window = var.maintenance_window
  apply_immediately  = var.apply_immediately
}
