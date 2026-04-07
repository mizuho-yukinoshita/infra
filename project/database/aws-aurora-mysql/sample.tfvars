system_name           = "app"
env                   = "dev"

# 注意！trueに切り替えると設定済みのパスワードは上書きされる
manage_master_password = false

subnet_group_name     = ""
security_group_ids    = ["sg-xxxxxxxx"]

# インスタンスクラス
writer_instance_class = "db.t3.medium"

reader_instance_class = "db.serverless"
reader_count          = 0

# Serverless v2のキャパシティ
serverless_min_capacity = 0
serverless_max_capacity = 0


# パラメータ
cluster_parameter_group_name = ""
cluster_parameters = []

db_parameter_group_name = ""
db_parameters = [
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

# タグ
default_tags = {}

cluster_tags = {}

writer_tags = {}

reader_tags = {}