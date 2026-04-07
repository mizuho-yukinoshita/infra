terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    key = "database/aws-aurora-mysql/terraform.tfstate"
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
    tags = merge(
      var.default_tags,
      {
        TerraformKey = "database/aws-aurora-mysql"
        SystemName   = var.system_name
        Environment  = var.env
        ManagedBy    = "Terraform"
      }
    )
  }
}

# ---------------------------------------------
# インスタンスパラメータグループ
# ---------------------------------------------
resource "aws_db_parameter_group" "main" {
  count = var.db_parameter_group_name == "" ? 1 : 0

  name_prefix = "${var.system_name}-${var.env}-aurora-db-parameter-group-"
  family      = "aurora-mysql8.0"
  description = "${var.system_name} ${var.env} Aurora DB Parameter Group"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }
}

# ---------------------------------------------
# クラスターパラメータグループ
# ---------------------------------------------
resource "aws_rds_cluster_parameter_group" "main" {
  count = var.cluster_parameter_group_name == "" ? 1 : 0

  name_prefix = "${var.system_name}-${var.env}-aurora-cluster-parameter-group-"
  family      = "aurora-mysql8.0"
  description = "${var.system_name} ${var.env} Aurora Cluster Parameter Group"

  parameter {
    apply_method = "immediate"
    name = "character_set_client"
    value = "utf8"
  }
  parameter {
    apply_method = "immediate"
    name = "character_set_connection"
    value = "utf8"
  }
  parameter {
    apply_method = "immediate"
    name = "character_set_database"
    value = "utf8"
  }
  parameter {
    apply_method = "immediate"
    name = "character_set_filesystem"
    value = "utf8"
  }
  parameter {
    apply_method = "immediate"
    name = "character_set_results"
    value = "utf8"
  }
  parameter {
    apply_method = "immediate"
    name = "character_set_server"
    value = "utf8"
  }

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }
}

# ---------------------------------------------
# Aurora クラスター
# ---------------------------------------------
resource "aws_rds_cluster" "main" {
  cluster_identifier              = "${var.system_name}-${var.env}-aurora-cluster"
  engine                          = "aurora-mysql"
  engine_version                  = "8.0.mysql_aurora.3.10.2"
  master_username                 = "root"
  port                            = 3306
  storage_encrypted               = var.storage_encrypted

  manage_master_user_password     = var.manage_master_password

  db_cluster_parameter_group_name = var.cluster_parameter_group_name == "" ? aws_rds_cluster_parameter_group.main[0].name : var.cluster_parameter_group_name
  db_subnet_group_name            = var.subnet_group_name
  vpc_security_group_ids          = var.security_group_ids

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  delete_automated_backups        = var.delete_automated_backups
  skip_final_snapshot             = var.skip_final_snapshot
  copy_tags_to_snapshot           = var.copy_tags_to_snapshot

  tags = merge(
    var.cluster_tags,
    { Name = "${var.system_name}-${var.env}-aurora-cluster" }
  )

  lifecycle {
    ignore_changes = [
      master_password,
      availability_zones
    ]
  }

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.serverless_max_capacity > 0 ? [1] : []
    content {
      min_capacity = var.serverless_min_capacity
      max_capacity = var.serverless_max_capacity
    }
  }
}

# ---------------------------------------------
# Aurora インスタンス
# ---------------------------------------------

# ▼ Writer
resource "aws_rds_cluster_instance" "writer" {
  identifier_prefix          = "${var.system_name}-${var.env}-aurora-instance-"
  cluster_identifier         = aws_rds_cluster.main.id
  engine                     = aws_rds_cluster.main.engine
  engine_version             = aws_rds_cluster.main.engine_version
  auto_minor_version_upgrade = false

  instance_class          = var.writer_instance_class
  db_parameter_group_name = var.db_parameter_group_name == "" ? aws_db_parameter_group.main[0].name : var.db_parameter_group_name
  db_subnet_group_name    = var.subnet_group_name

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  copy_tags_to_snapshot                 = var.copy_tags_to_snapshot

  tags = merge(
    var.writer_tags,
    { Name = "${var.system_name}-${var.env}-aurora-instance" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ▼ Reader
resource "aws_rds_cluster_instance" "reader" {
  count                   = var.reader_count

  promotion_tier             = count.index + 1

  identifier_prefix          = "${var.system_name}-${var.env}-aurora-instance-"
  cluster_identifier         = aws_rds_cluster.main.id
  engine                     = aws_rds_cluster.main.engine
  engine_version             = aws_rds_cluster.main.engine_version
  auto_minor_version_upgrade = false

  instance_class          = var.reader_instance_class
  db_parameter_group_name = var.db_parameter_group_name == "" ? aws_db_parameter_group.main[0].name : var.db_parameter_group_name
  db_subnet_group_name    = var.subnet_group_name

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  copy_tags_to_snapshot                 = var.copy_tags_to_snapshot

  tags = merge(
    var.reader_tags,
    { Name = "${var.system_name}-${var.env}-aurora-instance" }
  )
}