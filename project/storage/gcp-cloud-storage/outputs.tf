output "bucket_names" {
  description = "バケットの識別子 (マップのキー) => 実際のバケット名"
  value       = { for k, v in google_storage_bucket.this : k => v.name }
}

output "bucket_urls" {
  description = "バケットの識別子 => gs:// URL"
  value       = { for k, v in google_storage_bucket.this : k => v.url }
}

output "bucket_self_links" {
  description = "バケットの識別子 => self_link"
  value       = { for k, v in google_storage_bucket.this : k => v.self_link }
}
