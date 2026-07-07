provider "aws" {
  region = var.region

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
# パラメータグループの作成要否判定
# （null / "" のどちらでも「自前で作成する」と判定する）
# ---------------------------------------------
locals {
  create_db_parameter_group      = var.db_parameter_group_name == null || var.db_parameter_group_name == ""
  create_cluster_parameter_group = var.cluster_parameter_group_name == null || var.cluster_parameter_group_name == ""

  db_parameter_group_name      = local.create_db_parameter_group ? aws_db_parameter_group.main[0].name : var.db_parameter_group_name
  cluster_parameter_group_name = local.create_cluster_parameter_group ? aws_rds_cluster_parameter_group.main[0].name : var.cluster_parameter_group_name
}

# ---------------------------------------------
# インスタンスパラメータグループ
# ---------------------------------------------
resource "aws_db_parameter_group" "main" {
  count = local.create_db_parameter_group ? 1 : 0

  name_prefix = "${var.system_name}-${var.env}-aurora-db-parameter-group-"
  family      = var.db_parameter_group_family
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
  count = local.create_cluster_parameter_group ? 1 : 0

  name_prefix = "${var.system_name}-${var.env}-aurora-cluster-parameter-group-"
  family      = var.cluster_parameter_group_family
  description = "${var.system_name} ${var.env} Aurora Cluster Parameter Group"

  parameter {
    apply_method = "immediate"
    name         = "character_set_client"
    value        = "utf8"
  }
  parameter {
    apply_method = "immediate"
    name         = "character_set_connection"
    value        = "utf8"
  }
  parameter {
    apply_method = "immediate"
    name         = "character_set_database"
    value        = "utf8"
  }
  parameter {
    apply_method = "immediate"
    name         = "character_set_filesystem"
    value        = "utf8"
  }
  parameter {
    apply_method = "immediate"
    name         = "character_set_results"
    value        = "utf8"
  }
  parameter {
    apply_method = "immediate"
    name         = "character_set_server"
    value        = "utf8"
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
  cluster_identifier = "${var.system_name}-${var.env}-aurora-cluster"
  engine             = "aurora-mysql"
  engine_version     = var.engine_version
  master_username    = var.master_username
  port               = 3306
  storage_encrypted  = var.storage_encrypted
  kms_key_id         = var.kms_key_id

  # manage_master_user_password と master_password は排他。
  # manage_master_password = true の場合は Secrets Manager による自動管理（推奨）。
  # false の場合は TF_VAR_master_password 環境変数でパスワードを注入する。
  manage_master_user_password = var.manage_master_password ? true : null
  master_password             = var.manage_master_password ? null : var.master_password

  db_cluster_parameter_group_name = local.cluster_parameter_group_name
  db_subnet_group_name            = var.subnet_group_name
  vpc_security_group_ids          = var.security_group_ids

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  delete_automated_backups     = var.delete_automated_backups
  deletion_protection          = var.deletion_protection
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.final_snapshot_identifier
  copy_tags_to_snapshot        = var.copy_tags_to_snapshot

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
  identifier_prefix          = "${var.system_name}-${var.env}-aurora-writer-"
  cluster_identifier         = aws_rds_cluster.main.id
  engine                     = aws_rds_cluster.main.engine
  engine_version             = aws_rds_cluster.main.engine_version
  auto_minor_version_upgrade = false

  instance_class          = var.writer_instance_class
  db_parameter_group_name = local.db_parameter_group_name
  db_subnet_group_name    = var.subnet_group_name

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  tags = merge(
    var.writer_tags,
    { Name = "${var.system_name}-${var.env}-aurora-writer" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ▼ Reader
resource "aws_rds_cluster_instance" "reader" {
  count = var.reader_count

  promotion_tier = count.index + 1

  identifier_prefix          = "${var.system_name}-${var.env}-aurora-reader-"
  cluster_identifier         = aws_rds_cluster.main.id
  engine                     = aws_rds_cluster.main.engine
  engine_version             = aws_rds_cluster.main.engine_version
  auto_minor_version_upgrade = false

  instance_class          = var.reader_instance_class
  db_parameter_group_name = local.db_parameter_group_name
  db_subnet_group_name    = var.subnet_group_name

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  tags = merge(
    var.reader_tags,
    { Name = "${var.system_name}-${var.env}-aurora-reader" }
  )
}

# ---------------------------------------------
# Route 53 (既存のホストゾーンの参照)
# ---------------------------------------------
data "aws_route53_zone" "main" {
  count = var.route53_zone_name != null ? 1 : 0

  name         = var.route53_zone_name
  private_zone = var.is_route53_zone_private
}

# ---------------------------------------------
# Write/Read エンドポイントのレコード
# ---------------------------------------------
resource "aws_route53_record" "cluster_endpoint" {
  count = var.route53_zone_name != null ? 1 : 0

  zone_id = data.aws_route53_zone.main[0].zone_id

  name = var.route53_record_name != null ? "${var.route53_record_name}.${data.aws_route53_zone.main[0].name}" : "${var.system_name}-${var.env}-db.${data.aws_route53_zone.main[0].name}"

  type = "CNAME"
  ttl  = "300"

  records = [aws_rds_cluster.main.endpoint]
}

# ---------------------------------------------
# ReadOnly エンドポイントのレコード
# ---------------------------------------------
resource "aws_route53_record" "cluster_ro_endpoint" {
  count = var.route53_zone_name != null ? 1 : 0

  zone_id = data.aws_route53_zone.main[0].zone_id

  name = var.route53_record_name != null ? "${var.route53_record_name}-ro.${data.aws_route53_zone.main[0].name}" : "${var.system_name}-${var.env}-db-ro.${data.aws_route53_zone.main[0].name}"

  type = "CNAME"
  ttl  = "300"

  records = [aws_rds_cluster.main.reader_endpoint]
}
