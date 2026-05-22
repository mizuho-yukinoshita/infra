system_name        = "app"
env                = "dev"

subnet_ids         = ["subnet-xxxxxxxx"]
security_group_ids    = ["sg-xxxxxxxx"]

engine_version      = "8.1.0"
node_type           = "cache.t4g.micro"
parameter_group_name = "default.valkey8"

num_cache_clusters   = 1
multi_az_enabled    = false
automatic_failover_enabled = false