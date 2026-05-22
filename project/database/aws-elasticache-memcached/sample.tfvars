system_name        = "app"
env                = "dev"

subnet_ids         = ["subnet-xxxxxxxx"]
security_group_ids    = ["sg-xxxxxxxx"]

engine_version      = "1.6.22"
node_type           = "cache.t4g.micro"
parameter_group_name = "default.memcached1.6"

num_cache_nodes   = 1
