variable "system_name" {
  description = "システム名"
  type        = string
}

variable "env" {
  description = "環境名 (例: dev, stg, prd)"
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
  description = "（既存を利用する場合）クラスターパラメータグループ名"
  type = string
  default = ""
}

variable "db_parameter_group_name" {
  description = "（既存を利用する場合）インスタンスパラメータグループ名"
  type = string
  default = ""
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