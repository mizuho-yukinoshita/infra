英語の後に日本語があります。

---

***English***

# Infrastructure as Code (IaC) by Terraform

## Overview

This repository provides useful Terraform IaC templates along with Jenkins pipelines for CI/CD.

## Setup

Terraform requires a backend to store state files.

There are many options, and this repository provides a CloudFormation template for AWS S3.

### Prerequisites

* **Terraform:** v1.10.0 or later (Required for S3 Native Locking)
* **AWS CLI:** Installed and configured on the Jenkins agent
* **Jenkins:** With pipeline execution capabilities

### Key Features

* **DynamoDB-Free Locking:** Uses S3 native lock files (`use_lockfile = true`) for state management.
* **Strict Security Guardrails:** The S3 Bucket Policy includes an **Explicit Deny** to block all access except from the
  specific IAM Role/User executing the Jenkins pipeline, and enforces HTTPS connections.
* **Dynamic Configuration:** The Jenkins pipeline dynamically resolves the executor's AWS ARN and generates a reusable
  `backend.hcl` using the `writeFile` step.

### Directory Structure

```text
infra/
├── config/           # Auto-generated configurations (e.g., backend.hcl)
└── project/          
    └── terraform-backend
        ├── backend.sample.hcl           <-- Sample backend.hcl config file
        ├── cfn-terraform-backend.yaml   <-- CloudFormation template
        └── Jenkinsfile
```

### How It Works

1. **Identity Resolution:** Jenkins resolves its current AWS IAM Identity (Role or User) via
   `aws sts get-caller-identity`.
2. **Bootstrap Backend:** Executes `aws cloudformation deploy` to create the S3 bucket and applies a strict bucket
   policy restricting access to the resolved identity.
3. **Generate Config:** Retrieves the generated bucket name and writes to `config/backend.hcl`.
4. **Terraform Init:** Initializes Terraform using the generated backend configuration.

---

🇯🇵 ***日本語***

# TerraformによるInfrastructure as Code (IaC)

## 概要

便利なTerraform IaCテンプレートとCI/CD用のJenkinsパイプライン

## セットアップ

Terraformはステートファイルを保存するためのバックエンドが必要

様々な選択肢があるが、ここではAWS S3用のCloudFormationテンプレートを提供している。

### 前提条件

* **Terraform:** v1.10.0 以上 (S3ネイティブロックに必須)
* **AWS CLI:** Jenkinsエージェントにインストールおよび設定済みであること
* **Jenkins:** パイプライン実行環境

### 主な特徴

* **DynamoDB不要のロック機構:** ステート管理にS3ネイティブロック (`use_lockfile = true`) を使用
* **強固なセキュリティガードレール:** S3バケットポリシーに **明示的な拒否（Explicit Deny）**
  を設定し、Jenkinsパイプラインを実行する特定のIAMロール/ユーザー以外からのアクセスを完全に遮断し、HTTPS通信を強制
* **動的な設定ファイル生成:** Jenkinsパイプライン内で実行者のAWS ARNを動的に解決し、`writeFile` ステップを使用して再利用可能な
  `backend.hcl` を自動生成

### ディレクトリ構成

```text
infra/
├── config/           # 自動生成される設定ファイル配置場所 (backend.hcl 等)
└── project/          
    └── terraform-backend
        ├── backend.sample.hcl           <-- backend.hcl 設定ファイルのサンプル
        ├── cfn-terraform-backend.yaml   <-- CloudFormation テンプレート
        └── Jenkinsfile
```

### 実行フロー

1. **IAM認証情報の解決:** Jenkinsが `aws sts get-caller-identity` を使用し、自身の現在のAWS IAM Identity（ロールまたはユーザー）を解決
2. **バックエンドの構築:** `aws cloudformation deploy` を実行してS3バケットを作成し、解決されたIdentityのみにアクセスを制限する強固なバケットポリシーを適用
3. **設定ファイルの生成:** 生成されたバケット名を取得し、`config/backend.hcl` に書き出す
4. **Terraformの初期化:** 生成されたバックエンド設定を使用してTerraformを初期化