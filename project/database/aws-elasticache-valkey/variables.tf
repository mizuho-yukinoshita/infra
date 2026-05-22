variable "system_name" {
  description = "システム名"
  type        = string
}

variable "env" {
  description = "環境名 (例: dev, stg, prd)"
  type        = string
}

variable "subnet_ids" {
  description = "ElastiCacheを配置するサブネットIDのリスト"
  type        = list(string)
}

variable "security_group_ids" {
  description = "適用するセキュリティグループIDのリスト"
  type        = list(string)
}

variable "engine_version" {
  description = "Valkeyエンジンのバージョン"
  type        = string
  default     = "8.1.0"
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