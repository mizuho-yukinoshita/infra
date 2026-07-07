# コピーして <env>.tfvars (dev.tfvars / stg.tfvars / prod.tfvars) として利用する。
# 機密値はコミットせず、TF_VAR 環境変数や Secrets Manager で注入すること。
system_name        = "app"
env                = "dev" # dev / stg / prod
operation_iam_path = "role/sqs-operator"

# 以下は default のままでよければ省略可
# region                          = "ap-northeast-1"
# default_tags                    = {}
# main_visibility_timeout_seconds = 20
# main_message_retention_seconds  = 604800  # 7日
# dlq_visibility_timeout_seconds  = 30
# dlq_message_retention_seconds   = 1209600 # 14日 (最大値)
# max_receive_count               = 3
