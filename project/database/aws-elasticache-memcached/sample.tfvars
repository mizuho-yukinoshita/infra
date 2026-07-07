system_name = "app"
env         = "dev"
region      = "ap-northeast-1"

# プライベートサブネット必須
subnet_ids         = ["subnet-xxxxxxxx"]
security_group_ids = ["sg-xxxxxxxx"]

engine_version       = "1.6.22"
node_type            = "cache.t4g.micro"
parameter_group_name = "default.memcached1.6"

num_cache_nodes = 1
az_mode         = "single-az" # num_cache_nodes > 1 の場合は cross-az を推奨

transit_encryption_enabled = true

maintenance_window = "sun:18:00-sun:19:00"
