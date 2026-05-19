output "main_queue_url" {
  description = "メインキューのURL"
  value       = aws_sqs_queue.main.url
}

output "main_queue_arn" {
  description = "メインキューのARN"
  value       = aws_sqs_queue.main.arn
}

output "dl_queue_url" {
  description = "デッドレターキュー(DLQ)のURL"
  value       = aws_sqs_queue.dl.url
}

output "dl_queue_arn" {
  description = "デッドレターキュー(DLQ)のARN"
  value       = aws_sqs_queue.dl.arn
}