variable "system_name" {
  description = "システム名"
  type        = string
}

variable "env" {
  description = "環境名 (dev / stg / prod)"
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
  description = "全リソースに付与する追加タグ"
  type        = map(string)
  default     = {}
}

variable "operation_iam_path" {
  description = "SQSキューの操作を許可するIAMのパス (例: role/sqs-operator)"
  type        = string
}

variable "main_visibility_timeout_seconds" {
  description = "メインキューの可視性タイムアウト (秒)"
  type        = number
  default     = 20
}

variable "main_message_retention_seconds" {
  description = "メインキューのメッセージ保持期間 (秒)"
  type        = number
  default     = 604800 # 7日
}

variable "dlq_visibility_timeout_seconds" {
  description = "DLQの可視性タイムアウト (秒)"
  type        = number
  default     = 30
}

variable "dlq_message_retention_seconds" {
  description = "DLQのメッセージ保持期間 (秒)。調査猶予を確保するためメインキューより長くする"
  type        = number
  default     = 1209600 # 14日 (最大値)

  validation {
    condition     = var.dlq_message_retention_seconds >= var.main_message_retention_seconds
    error_message = "dlq_message_retention_seconds はメインキューの保持期間以上にしてください。"
  }
}

variable "max_receive_count" {
  description = "メインキューでの最大受信回数。超過したメッセージはDLQへ移動する"
  type        = number
  default     = 3
}
