system_name = "app"
env         = "dev"
region      = "ap-northeast-1"

# ネットワーク（既存リソースを指定）
subnet_group_name  = "your-db-subnet-group"
security_group_ids = ["sg-xxxxxxxx"]

# マスターユーザー
master_username = "admin"
# true: AWS Secrets Managerによる自動管理（推奨）
# false にする場合、master_password は tfvars に書かず
# 環境変数 TF_VAR_master_password で注入すること
manage_master_password = true

# エンジン
engine_version = "8.0.mysql_aurora.3.10.2"

# 暗号化
storage_encrypted = true
# 未指定の場合は AWS マネージドキーを使用
# kms_key_id = "arn:aws:kms:ap-northeast-1:123456789012:key/xxxxxxxx"

# 削除保護（prodでは true / skip_final_snapshot = false を推奨）
deletion_protection      = true
skip_final_snapshot      = true
delete_automated_backups = true
# skip_final_snapshot = false の場合は必須
# final_snapshot_identifier = "app-dev-aurora-final-snapshot"

# インスタンスクラス
writer_instance_class = "db.serverless"

reader_instance_class = "db.serverless"
reader_count          = 0

# Serverless v2のキャパシティ
serverless_min_capacity = 0
serverless_max_capacity = 2

# パラメータ（name を null または "" にすると自前で作成する）
cluster_parameter_group_name   = ""
cluster_parameter_group_family = "aurora-mysql8.0"
cluster_parameters             = []

db_parameter_group_name   = ""
db_parameter_group_family = "aurora-mysql8.0"
db_parameters = [
  { apply_method = "immediate", name = "eq_range_index_dive_limit", value = "1000" },
  { apply_method = "immediate", name = "innodb_lock_wait_timeout", value = "15" },
  { apply_method = "immediate", name = "log_queries_not_using_indexes", value = "0" },
  { apply_method = "immediate", name = "log_slow_admin_statements", value = "1" },
  { apply_method = "immediate", name = "log_slow_replica_statements", value = "1" },
  { apply_method = "immediate", name = "long_query_time", value = "1" },
  { apply_method = "immediate", name = "max_connect_errors", value = "999999999" },
  { apply_method = "immediate", name = "range_optimizer_max_mem_size", value = "16777216" },
  { apply_method = "immediate", name = "slow_query_log", value = "1" },
  { apply_method = "immediate", name = "wait_timeout", value = "60" },
  { apply_method = "pending-reboot", name = "explicit_defaults_for_timestamp", value = "0" }
]

# Backup
backup_retention_period      = 7
preferred_backup_window      = "16:41-17:11"
preferred_maintenance_window = "sun:20:01-sun:20:31"
copy_tags_to_snapshot        = true

# Monitoring
performance_insights_enabled          = false
performance_insights_retention_period = 7
enabled_cloudwatch_logs_exports       = ["slowquery"]

# DNS
route53_zone_name       = "aws.internal"
is_route53_zone_private = true
# レコード名上書き可能。デフォルト: ${system_name}-${env}-db
# route53_record_name = ""

# タグ
default_tags = {}

cluster_tags = {}

writer_tags = {}

reader_tags = {}
