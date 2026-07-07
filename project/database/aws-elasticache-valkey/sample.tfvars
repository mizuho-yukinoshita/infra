system_name = "app"
env         = "dev"
region      = "ap-northeast-1"

# プライベートサブネット必須
subnet_ids         = ["subnet-xxxxxxxx"]
security_group_ids = ["sg-xxxxxxxx"]

engine_version       = "8.1"
node_type            = "cache.t4g.micro"
parameter_group_name = "default.valkey8"

num_cache_clusters         = 1
multi_az_enabled           = false
automatic_failover_enabled = false

at_rest_encryption_enabled = true
transit_encryption_enabled = true
# kms_key_id = "arn:aws:kms:ap-northeast-1:123456789012:key/xxxxxxxx" # 未指定時はAWSマネージドキー

# auth_token は tfvars に書かず、環境変数 TF_VAR_auth_token で注入する

snapshot_retention_limit = 7
snapshot_window          = "17:00-18:00"

maintenance_window = "sun:18:00-sun:19:00"
apply_immediately  = false
