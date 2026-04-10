variable "system_name" {
  description = "システム名"
  type        = string
}

variable "env" {
  description = "環境名 (例: dev, stg, prd)"
  type        = string
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

variable "manage_master_password" {
  description = "AWS Secrets Managerによるパスワード自動管理を有効にするか"
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "ストレージの暗号化を有効にするか"
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
  description = "クラスター削除時に最終スナップショットの取得をスキップするか"
  type        = bool
  default     = true
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
  description = "（既存を利用する場合）クラスターパラメータグループ名"
  type = string
  default = null
}

variable "db_parameter_group_name" {
  description = "（既存を利用する場合）インスタンスパラメータグループ名"
  type = string
  default = null
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