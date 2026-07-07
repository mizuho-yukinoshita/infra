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
  description = "Memcachedエンジンのバージョン"
  type        = string
  default     = "1.6.22"
}

variable "node_type" {
  description = "キャッシュノードのインスタンスタイプ"
  type        = string
  default     = "cache.t4g.micro"
}

variable "parameter_group_name" {
  description = "適用するパラメータグループ名"
  type        = string
  default     = "default.memcached1.6"
}

variable "num_cache_nodes" {
  description = "クラスター内に作成するMemcachedノードの数"
  type        = number
  default     = 1
}

variable "az_mode" {
  description = "AZ配置モード (single-az / cross-az)。num_cache_nodes > 1 の場合は cross-az を推奨"
  type        = string
  default     = "single-az"

  validation {
    condition     = contains(["single-az", "cross-az"], var.az_mode)
    error_message = "az_mode は single-az または cross-az を指定してください。"
  }
}

variable "transit_encryption_enabled" {
  description = "転送中の暗号化 (TLS) を有効にするか (Memcached 1.6.12 以降が前提)"
  type        = bool
  default     = true
}

variable "maintenance_window" {
  description = "メンテナンスウィンドウ (UTC)。例: sun:18:00-sun:19:00 (JST 月曜 3:00-4:00)"
  type        = string
  default     = "sun:18:00-sun:19:00"
}
