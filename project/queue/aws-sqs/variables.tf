variable "system_name" {
  description = "システム名"
  type        = string
}

variable "env" {
  description = "環境名 (例: dev, stg, prod)"
  type        = string
}

variable "operation_iam_path" {
  description = "SQSキューの操作を許可するIAMのパス (例: role/sqs-operator)"
  type        = string
}