output "cluster_endpoint" {
  description = "作成したAuroraクラスターの Write/Read エンドポイント"
  value       = var.route53_zone_name != null ? aws_route53_record.cluster_endpoint[0].fqdn : aws_rds_cluster.main.endpoint
}

output "cluster_ro_endpoint" {
  description = "作成したAuroraクラスターの ReadOnly エンドポイント"
  value       = var.route53_zone_name != null ? aws_route53_record.cluster_ro_endpoint[0].fqdn : aws_rds_cluster.main.reader_endpoint
}

output "cluster_port" {
  description = "作成したAuroraクラスターのポート番号"
  value       = aws_rds_cluster.main.port
}