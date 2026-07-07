variable "system_name" {
  description = "システム名"
  type        = string
}

variable "env" {
  description = "環境名 (dev, stg, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.env)
    error_message = "env は dev, stg, prod のいずれかを指定してください。"
  }
}

variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "subnet_group_name" {
  description = "DBサブネットグループ名"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "適用するセキュリティグループIDのリスト"
  type        = list(string)
}

variable "master_username" {
  description = "マスターユーザー名"
  type        = string
  default     = "admin"
}

variable "manage_master_password" {
  description = "AWS Secrets Managerによるマスターパスワードの自動管理を有効にするか（推奨: true）"
  type        = bool
  default     = true
}

variable "master_password" {
  description = "マスターパスワード（manage_master_password = false の場合のみ使用）。tfvars には書かず、環境変数 TF_VAR_master_password で注入すること"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.manage_master_password || var.master_password != null
    error_message = "manage_master_password = false の場合は master_password を指定してください（TF_VAR_master_password で注入）。"
  }
}

variable "engine_version" {
  description = "Aurora MySQLのエンジンバージョン"
  type        = string
  default     = "8.0.mysql_aurora.3.10.2"
}

variable "storage_encrypted" {
  description = "ストレージの暗号化を有効にするか"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "暗号化に使用するKMSキーのARN（未指定の場合はAWSマネージドキーを使用）"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "クラスターの削除保護を有効にするか"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "自動バックアップの保持期間（日）"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "自動バックアップを実行する時間帯（UTC）"
  type        = string
  default     = "19:30-20:59"
}

variable "preferred_maintenance_window" {
  description = "メンテナンスを実行する時間帯（UTC）"
  type        = string
  default     = "sat:20:30-sat:20:59"
}

variable "delete_automated_backups" {
  description = "クラスター削除時に自動バックアップも削除するか"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "クラスター削除時に最終スナップショットの取得をスキップするか（prodではfalse推奨）"
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "最終スナップショットの識別子（skip_final_snapshot = false の場合に必須）"
  type        = string
  default     = null

  validation {
    condition     = var.skip_final_snapshot || var.final_snapshot_identifier != null
    error_message = "skip_final_snapshot = false の場合は final_snapshot_identifier を指定してください。"
  }
}

variable "copy_tags_to_snapshot" {
  description = "スナップショットにタグをコピーするか"
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "CloudWatchへエクスポートするログの種類"
  type        = list(string)
  default     = []
}

variable "performance_insights_enabled" {
  description = "Performance Insightsを有効にするか"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Performance Insightsのデータ保持期間（日）"
  type        = number
  default     = 7
}

variable "cluster_parameter_group_name" {
  description = "（既存を利用する場合）クラスターパラメータグループ名。null または \"\" の場合は自前で作成する"
  type        = string
  default     = null
}

variable "cluster_parameter_group_family" {
  description = "自前で作成するクラスターパラメータグループのファミリー"
  type        = string
  default     = "aurora-mysql8.0"
}

variable "db_parameter_group_name" {
  description = "（既存を利用する場合）インスタンスパラメータグループ名。null または \"\" の場合は自前で作成する"
  type        = string
  default     = null
}

variable "db_parameter_group_family" {
  description = "自前で作成するインスタンスパラメータグループのファミリー"
  type        = string
  default     = "aurora-mysql8.0"
}

variable "writer_instance_class" {
  description = "Writer（マスター）のインスタンスクラス"
  type        = string
}

variable "reader_instance_class" {
  description = "Reader（リードレプリカ）のインスタンスクラス"
  type        = string
  default     = null
}

variable "reader_count" {
  description = "作成するReaderの台数（0なら作らない）"
  type        = number
  default     = 0

  validation {
    condition     = var.reader_count == 0 || var.reader_instance_class != null
    error_message = "reader_count > 0 の場合は reader_instance_class を指定してください。"
  }
}

variable "serverless_min_capacity" {
  description = "Serverless v2の最小ACU"
  type        = number
  default     = 0
}

variable "serverless_max_capacity" {
  description = "Serverless v2の最大ACU（0の場合はServerless設定を行わない）"
  type        = number
  default     = 0

  validation {
    condition     = (var.writer_instance_class != "db.serverless" && var.reader_instance_class != "db.serverless") || var.serverless_max_capacity > 0
    error_message = "インスタンスクラスに db.serverless を指定する場合は serverless_max_capacity を 1 以上にしてください。"
  }
}

variable "cluster_parameters" {
  description = "クラスターパラメータのリスト"
  type = list(object({
    name         = string
    value        = string
    apply_method = string
  }))
  default = []
}

variable "db_parameters" {
  description = "インスタンスパラメータのリスト"
  type = list(object({
    name         = string
    value        = string
    apply_method = string
  }))
  default = []
}

variable "route53_zone_name" {
  description = "クラスターエンドポイントのレコードを追加するRoute 53のホストゾーン名"
  type        = string
  default     = null
}

variable "is_route53_zone_private" {
  description = "Route 53のホストゾーンがプライベート（VPC内のみ）かどうか"
  type        = bool
  default     = true
}

variable "route53_record_name" {
  description = "Route 53のレコード名。指定しない場合は\${system_name}-\${env}-db"
  type        = string
  default     = null
}

variable "default_tags" {
  description = "リソースに付与する共通タグ"
  type        = map(string)
  default     = {}
}

variable "cluster_tags" {
  description = "クラスターに付与するタグ"
  type        = map(string)
  default     = {}
}

variable "writer_tags" {
  description = "Writerに付与するタグ"
  type        = map(string)
  default     = {}
}

variable "reader_tags" {
  description = "Readerに付与するタグ"
  type        = map(string)
  default     = {}
}
