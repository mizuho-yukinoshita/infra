provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        TerraformKey = "queue/aws-sqs"
        SystemName   = var.system_name
        Environment  = var.env
        ManagedBy    = "Terraform"
      },
      var.default_tags
    )
  }
}

# 実行中のAWSアカウントID・パーティションを取得するため
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# ---------------------------------------------
# デッドレターキュー (DLQ)
# ---------------------------------------------
resource "aws_sqs_queue" "dl" {
  name_prefix                = "${var.system_name}-${var.env}-dead-letter-queue-"
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = var.dlq_visibility_timeout_seconds
  message_retention_seconds  = var.dlq_message_retention_seconds
  max_message_size           = 262144
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dl.url

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.main.arn]
  })
}

# ---------------------------------------------
# メインのキュー
# ---------------------------------------------
resource "aws_sqs_queue" "main" {
  name_prefix                = "${var.system_name}-${var.env}-queue-"
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = var.main_visibility_timeout_seconds
  message_retention_seconds  = var.main_message_retention_seconds
  max_message_size           = 262144

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dl.arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id
  policy    = data.aws_iam_policy_document.main.json
}

data "aws_iam_policy_document" "main" {
  statement {
    sid    = "AllowIAM"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:${var.operation_iam_path}"]
    }
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [aws_sqs_queue.main.arn]
  }
}
