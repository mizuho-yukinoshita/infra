variable "system_name" {
  description = "システム名 (バケット名とラベルに使用するため英小文字・数字・ハイフンのみ)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.system_name))
    error_message = "system_name は英小文字始まりで、英小文字・数字・ハイフンのみ使用できます (GCSのバケット名・ラベル制約)。"
  }
}

variable "env" {
  description = "環境名 (dev / stg / prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.env)
    error_message = "env は dev, stg, prod のいずれかを指定してください。"
  }
}

variable "gcp_project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "location" {
  description = "バケットのデフォルトロケーション (エントリごとに location で上書き可能)"
  type        = string
  default     = "asia-northeast1"
}

variable "default_labels" {
  description = "全バケットに付与する追加ラベル。キー・値とも英小文字・数字・ハイフン・アンダースコアのみ使用可"
  type        = map(string)
  default     = {}
}

variable "buckets" {
  description = "作成するバケットの定義。キーはバケットの識別子 (name 未指定の場合、バケット名は <system_name>-<env>-<キー> になる)"
  type = map(object({
    name                     = optional(string)
    location                 = optional(string)
    storage_class            = optional(string, "STANDARD")
    versioning               = optional(bool, false)
    force_destroy            = optional(bool, false)
    public_access_prevention = optional(string, "enforced")
    kms_key_name             = optional(string)
    lifecycle_rules = optional(list(object({
      action             = string
      storage_class      = optional(string)
      age_days           = optional(number)
      num_newer_versions = optional(number)
      with_state         = optional(string)
    })), [])
    iam_members = optional(map(list(string)), {})
    labels      = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for v in var.buckets : contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], v.storage_class)
    ])
    error_message = "storage_class は STANDARD, NEARLINE, COLDLINE, ARCHIVE のいずれかを指定してください。"
  }

  validation {
    condition = alltrue([
      for v in var.buckets : contains(["enforced", "inherited"], v.public_access_prevention)
    ])
    error_message = "public_access_prevention は enforced または inherited を指定してください。"
  }

  validation {
    condition = alltrue([
      for v in var.buckets : alltrue([
        for r in v.lifecycle_rules : contains(["Delete", "SetStorageClass"], r.action)
      ])
    ])
    error_message = "lifecycle_rules の action は Delete または SetStorageClass を指定してください。"
  }

  validation {
    condition = alltrue([
      for v in var.buckets : alltrue([
        for r in v.lifecycle_rules : (r.action != "SetStorageClass" || r.storage_class != null)
      ])
    ])
    error_message = "action = SetStorageClass のライフサイクルルールには storage_class を指定してください。"
  }

  validation {
    condition = alltrue([
      for v in var.buckets : alltrue([
        for role in keys(v.iam_members) : startswith(role, "roles/")
      ])
    ])
    error_message = "iam_members のキーはロール名 (roles/ で始まる文字列) を指定してください。"
  }

  validation {
    condition = alltrue([
      for v in var.buckets : alltrue([
        for members in values(v.iam_members) : alltrue([
          for m in members : strcontains(m, ":")
        ])
      ])
    ])
    error_message = "iam_members のメンバーには serviceAccount: / user: / group: 等のプレフィックスを付けてください。"
  }
}
