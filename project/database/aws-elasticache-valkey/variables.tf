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

variable "default_tags" {
  description = "全リソースに付与する追加タグ (固定タグにマージされる)"
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "ElastiCacheを配置するサブネットIDのリスト (プライベートサブネット必須)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "適用するセキュリティグループIDのリスト (プライベートサブネット内からのアクセスのみ許可すること)"
  type        = list(string)
}

variable "engine_version" {
  description = "Valkeyエンジンのバージョン (v7以降は「メジャー.マイナー」形式のみ。例: 8.1)"
  type        = string
  default     = "8.1"
}

variable "node_type" {
  description = "キャッシュノードのインスタンスタイプ"
  type        = string
  default     = "cache.t4g.micro"
}

variable "parameter_group_name" {
  description = "適用するパラメータグループ名"
  type        = string
  default     = "default.valkey8"
}

variable "automatic_failover_enabled" {
  description = "自動フェイルオーバーを有効にするか (*Requires num_cache_clusters >= 2)"
  type        = bool
  default     = false
}

variable "multi_az_enabled" {
  description = "マルチAZ配置を有効にするか (*Requires automatic_failover_enabled = true)"
  type        = bool
  default     = false
}

variable "num_cache_clusters" {
  description = "クラスター内のノード数"
  type        = number
  default     = 1
}

variable "at_rest_encryption_enabled" {
  description = "保存時の暗号化を有効にするか"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "転送中の暗号化 (TLS) を有効にするか"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "保存時の暗号化に使用するKMSキーのARN (null の場合はAWSマネージドキーを使用)"
  type        = string
  default     = null
}

variable "auth_token" {
  description = "AUTHトークン (transit_encryption_enabled = true が前提)。tfvars には記載せず、環境変数 TF_VAR_auth_token で注入すること"
  type        = string
  sensitive   = true
  default     = null
}

variable "snapshot_retention_limit" {
  description = "自動スナップショットの保持日数 (0 で自動スナップショット無効)"
  type        = number
  default     = 7
}

variable "snapshot_window" {
  description = "自動スナップショットを取得する時間帯 (UTC)。maintenance_window と重複しないこと"
  type        = string
  default     = "17:00-18:00"
}

variable "maintenance_window" {
  description = "メンテナンスウィンドウ (UTC)。例: sun:18:00-sun:19:00 (JST 月曜 3:00-4:00)"
  type        = string
  default     = "sun:18:00-sun:19:00"
}

variable "apply_immediately" {
  description = "変更を即時適用するか (false の場合は次回メンテナンスウィンドウで適用)"
  type        = bool
  default     = false
}
