terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  backend "s3" {
    # bucket / region / key などは Jenkins が生成する backend.hcl から
    # terraform init -backend-config で注入する。
    # key の規約: database/aws-elasticache-valkey/${ENV}/terraform.tfstate
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.73"
    }
  }
}
