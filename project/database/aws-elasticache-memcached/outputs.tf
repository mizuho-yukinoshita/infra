output "memcached_cluster_address" {
  description = "Memcachedのクラスターエンドポイント"
  value       = aws_elasticache_cluster.main.cluster_address
}

output "memcached_configuration_endpoint" {
  description = "Memcachedの設定エンドポイント"
  value       = aws_elasticache_cluster.main.configuration_endpoint
}