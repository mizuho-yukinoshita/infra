terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    key = "queue/aws-sqs/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      TerraformKey = "queue/aws-sqs"
      SystemName   = var.system_name
      Environment  = var.env
      ManagedBy    = "Terraform"
    }
  }
}

# 実行中のAWSアカウントIDを取得するため
data "aws_caller_identity" "current" {}

# ---------------------------------------------
# デッドレターキュー (DLQ)
# ---------------------------------------------
resource "aws_sqs_queue" "dl" {
  name_prefix                = "${var.system_name}-${var.env}-DLQueue-"
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 30
  message_retention_seconds  = 604800
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
  name_prefix                = "${var.system_name}-${var.env}-Queue-"
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 20
  message_retention_seconds  = 604800
  max_message_size           = 262144

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dl.arn
    maxReceiveCount     = 3
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
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:${var.operation_iam_path}"]
    }
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.main.arn]
  }
}