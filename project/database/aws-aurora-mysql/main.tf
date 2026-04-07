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

  name_prefix = "${var.system_name}-${var.env}-aurora-db-parameter-group"
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

  name_prefix = "${var.system_name}-${var.env}-aurora-cluster-parameter-group"
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

  manage_master_user_password     = var.manage_master_password

  db_cluster_parameter_group_name = var.cluster_parameter_group_name == "" ? aws_rds_cluster_parameter_group.main[0].name : var.cluster_parameter_group_name
  db_subnet_group_name            = var.subnet_group_name
  vpc_security_group_ids          = var.security_group_ids

  backup_retention_period         = 7
  preferred_backup_window         = "16:41-17:11"
  preferred_maintenance_window    = "sun:20:01-sun:20:31"
  delete_automated_backups        = true
  skip_final_snapshot             = true
  storage_encrypted               = false

  enabled_cloudwatch_logs_exports = ["slowquery"]

  tags = merge(
    var.cluster_tags,
    { Name = "${var.system_name}-${var.env}-aurora-main-cluster" }
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
  identifier                 = "${var.system_name}-${var.env}-aurora-writer"
  cluster_identifier         = aws_rds_cluster.main.id
  engine                     = aws_rds_cluster.main.engine
  engine_version             = aws_rds_cluster.main.engine_version
  auto_minor_version_upgrade = false

  instance_class          = var.writer_instance_class
  db_parameter_group_name = var.db_parameter_group_name == "" ? aws_db_parameter_group.main[0].name : var.db_parameter_group_name
  db_subnet_group_name    = var.subnet_group_name

  tags = merge(
    var.writer_tags,
    { Name = "${var.system_name}-${var.env}-aurora-writer" }
  )
}

# ▼ Reader
resource "aws_rds_cluster_instance" "reader" {
  count                   = var.reader_count

  identifier                 = "${var.system_name}-${var.env}-aurora-reader${count.index + 1}"
  cluster_identifier         = aws_rds_cluster.main.id
  engine                     = aws_rds_cluster.main.engine
  engine_version             = aws_rds_cluster.main.engine_version
  auto_minor_version_upgrade = false

  instance_class          = var.reader_instance_class
  db_parameter_group_name = var.db_parameter_group_name == "" ? aws_db_parameter_group.main[0].name : var.db_parameter_group_name
  db_subnet_group_name    = var.subnet_group_name

  tags = merge(
    var.reader_tags,
    { Name = "${var.system_name}-${var.env}-aurora-reader${count.index + 1}" }
  )
}