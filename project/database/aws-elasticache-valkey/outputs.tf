output "valkey_primary_endpoint" {
  description = "Valkeyのプライマリエンドポイント"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "valkey_reader_endpoint" {
  description = "Valkeyの読み取り専用エンドポイント"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}