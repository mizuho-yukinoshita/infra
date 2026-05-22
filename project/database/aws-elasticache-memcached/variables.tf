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