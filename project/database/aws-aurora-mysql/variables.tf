variable "system_name" {
  description = "システム名"
  type        = string
}

variable "env" {
  description = "環境名 (例: stg, prd)"
  type        = string
}

variable "manage_master_password" {
  description = "AWS Secrets Managerによるパスワード自動管理を有効にするか"
  type        = bool
  default     = false
}

variable "subnet_group_name" {
  description = "DBサブネットグループ名"
  type        = string
}

variable "security_group_ids" {
  description = "適用するセキュリティグループIDのリスト"
  type        = list(string)
}

variable "cluster_parameter_group_name" {
  description = "クラスターパラメータグループ名"
  type        = string
}

variable "instance_parameter_group_name" {
  description = "DBパラメータグループ名"
  type        = string
}

variable "writer_instance_class" {
  description = "Writer（マスター）のインスタンスクラス"
  type        = string
}

variable "reader_instance_class" {
  description = "Reader（リードレプリカ）のインスタンスクラス"
  type        = string
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

variable "instance_parameters" {
  description = "インスタンスパラメータのリスト"
  type = list(object({
    name         = string
    value        = string
    apply_method = string
  }))
  default = [
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
}

variable "common_tags" {
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