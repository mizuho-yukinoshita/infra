# AWS Aurora MySQL テンプレート

Aurora MySQL クラスター（Writer 1台 + 任意台数の Reader、Provisioned / Serverless v2 対応）を構築する Terraform テンプレートです。パラメータグループの作成（または既存の利用）、Route 53 のエンドポイントレコード登録もあわせて行います。

## 前提リソース

以下は本テンプレートでは作成しないため、事前に用意してください。

- VPC / サブネット
- DB サブネットグループ（`subnet_group_name` で指定）
- セキュリティグループ（`security_group_ids` で指定）
- Route 53 ホストゾーン（DNS レコードを作る場合。`route53_zone_name` で指定）
- Terraform backend 用の S3 バケット（Jenkins が CloudFormation スタックから取得）
- （任意）KMS キー（`kms_key_id` を指定する場合）

## State の管理

backend の `key` はコードには書かず、Jenkins が生成する `backend.hcl` で
`database/aws-aurora-mysql/${ENV}/terraform.tfstate` を指定する規約です。
ロックは S3 ネイティブロック（`use_lockfile = true`）を使用します。

## 変数一覧

| 変数名 | 型 | デフォルト | 説明 |
| --- | --- | --- | --- |
| `system_name` | string | （必須） | システム名 |
| `env` | string | （必須） | 環境名（`dev` / `stg` / `prod` のみ） |
| `region` | string | `ap-northeast-1` | AWS リージョン |
| `subnet_group_name` | string | `null` | DB サブネットグループ名 |
| `security_group_ids` | list(string) | （必須） | 適用するセキュリティグループ ID のリスト |
| `master_username` | string | `admin` | マスターユーザー名 |
| `manage_master_password` | bool | `true` | Secrets Manager によるパスワード自動管理（推奨） |
| `master_password` | string (sensitive) | `null` | `manage_master_password = false` の場合のみ。**tfvars に書かず `TF_VAR_master_password` で注入** |
| `engine_version` | string | `8.0.mysql_aurora.3.10.2` | Aurora MySQL エンジンバージョン |
| `storage_encrypted` | bool | `true` | ストレージ暗号化 |
| `kms_key_id` | string | `null` | 暗号化用 KMS キー ARN（未指定時は AWS マネージドキー） |
| `deletion_protection` | bool | `true` | クラスターの削除保護 |
| `backup_retention_period` | number | `7` | 自動バックアップ保持期間（日） |
| `preferred_backup_window` | string | `19:30-20:59` | バックアップ時間帯（UTC） |
| `preferred_maintenance_window` | string | `sat:20:30-sat:20:59` | メンテナンス時間帯（UTC） |
| `delete_automated_backups` | bool | `true` | クラスター削除時に自動バックアップも削除するか |
| `skip_final_snapshot` | bool | `true` | 削除時の最終スナップショット取得をスキップするか（prod は `false` 推奨） |
| `final_snapshot_identifier` | string | `null` | 最終スナップショット識別子（`skip_final_snapshot = false` 時に必須） |
| `copy_tags_to_snapshot` | bool | `true` | スナップショットへのタグコピー |
| `enabled_cloudwatch_logs_exports` | list(string) | `[]` | CloudWatch へエクスポートするログ種別 |
| `performance_insights_enabled` | bool | `false` | Performance Insights の有効化 |
| `performance_insights_retention_period` | number | `7` | Performance Insights のデータ保持期間（日） |
| `cluster_parameter_group_name` | string | `null` | 既存クラスターパラメータグループ名（`null` / `""` なら自前作成） |
| `cluster_parameter_group_family` | string | `aurora-mysql8.0` | 自前作成時のクラスターパラメータグループのファミリー |
| `db_parameter_group_name` | string | `null` | 既存インスタンスパラメータグループ名（`null` / `""` なら自前作成） |
| `db_parameter_group_family` | string | `aurora-mysql8.0` | 自前作成時のインスタンスパラメータグループのファミリー |
| `writer_instance_class` | string | （必須） | Writer のインスタンスクラス（Serverless v2 は `db.serverless`） |
| `reader_instance_class` | string | `null` | Reader のインスタンスクラス（`reader_count > 0` の場合必須） |
| `reader_count` | number | `0` | Reader の台数（0 なら作らない） |
| `serverless_min_capacity` | number | `0` | Serverless v2 の最小 ACU |
| `serverless_max_capacity` | number | `0` | Serverless v2 の最大 ACU（`db.serverless` 指定時は 1 以上が必須） |
| `cluster_parameters` | list(object) | `[]` | クラスターパラメータのリスト |
| `db_parameters` | list(object) | `[]` | インスタンスパラメータのリスト |
| `route53_zone_name` | string | `null` | レコードを追加する Route 53 ホストゾーン名（`null` なら DNS レコードを作らない） |
| `is_route53_zone_private` | bool | `true` | ホストゾーンがプライベートかどうか |
| `route53_record_name` | string | `null` | レコード名（未指定時は `${system_name}-${env}-db`） |
| `default_tags` | map(string) | `{}` | 全リソース共通タグ |
| `cluster_tags` | map(string) | `{}` | クラスターのタグ |
| `writer_tags` | map(string) | `{}` | Writer のタグ |
| `reader_tags` | map(string) | `{}` | Reader のタグ |

## tfvars の運用

- このリポジトリはテンプレート集のため、同梱するのは雛形の `sample.tfvars` のみです。テンプレートを実プロジェクトで採用する際に、環境別の `dev.tfvars` / `stg.tfvars` / `prod.tfvars` を `cp sample.tfvars <env>.tfvars` で作成し、そのままリポジトリにコミットします（`.gitignore` は tfvars を除外していません）。
- 環境別 tfvars がコミットされていれば Jenkins のクリーンチェックアウトにも含まれるため、`Jenkinsfile` の `-var-file="${ENV}.tfvars"` はそのまま動きます。Config File Provider 等での外部注入は不要です。
- **機密値（パスワード等）は tfvars に書かない**こと。`manage_master_password = true`（デフォルト）で Secrets Manager に管理させるか、やむを得ず固定パスワードを使う場合は環境変数 `TF_VAR_master_password` で注入します。

```sh
# manage_master_password = false の場合のみ
export TF_VAR_master_password='xxxxxxxx'
```

## apply / destroy の流れ

通常は Jenkins パイプライン（`Jenkinsfile`）から `ACTION`（apply / destroy）と `ENV`（dev / stg / prod）を選んで実行します。手動で実行する場合は以下の通りです。

```sh
cd project/database/aws-aurora-mysql

# 環境別 tfvars が未作成の場合は雛形から作成してコミットする
cp sample.tfvars dev.tfvars  # 値を環境に合わせて編集

# init（backend.hcl は bucket / region / key などを指定したファイル）
terraform init -backend-config=backend.hcl

# plan / apply
terraform plan -var-file=dev.tfvars -out=tfplan
terraform apply tfplan

# destroy（prod は deletion_protection = true のため、
# 先に false に変更して apply しない限り destroy は失敗します）
terraform plan -destroy -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
```
