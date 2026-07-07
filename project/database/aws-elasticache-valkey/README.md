# aws-elasticache-valkey

ElastiCache for Valkey のレプリケーショングループを構築する Terraform テンプレート。
セッションストアやキャッシュ用途で、レプリケーション・自動フェイルオーバー・AUTH・暗号化が必要な場合に使用する。

## 前提リソース

- VPC / プライベートサブネット（`subnet_ids` にはプライベートサブネットのみ指定すること）
- セキュリティグループ（アプリケーションからポート 6379 へのインバウンドを許可したもの）
- Terraform backend 用 S3 バケット（CloudFormation スタック `terraform-backend` で作成済みであること）

## backend / state キー規約

backend の `bucket` / `region` / `key` は Jenkins が生成する `backend.hcl` から注入する。

```
key = "database/aws-elasticache-valkey/${ENV}/terraform.tfstate"
```

## 変数一覧

| 変数名 | 型 | デフォルト | 説明 |
| --- | --- | --- | --- |
| `system_name` | string | - | システム名 |
| `env` | string | - | 環境名 (dev / stg / prod) |
| `region` | string | `ap-northeast-1` | AWS リージョン |
| `default_tags` | map(string) | `{}` | 固定タグにマージする追加タグ |
| `subnet_ids` | list(string) | - | 配置先サブネット ID（プライベートサブネット必須） |
| `security_group_ids` | list(string) | - | 適用するセキュリティグループ ID |
| `engine_version` | string | `8.1` | エンジンバージョン（v7 以降は「メジャー.マイナー」形式のみ） |
| `node_type` | string | `cache.t4g.micro` | ノードのインスタンスタイプ |
| `parameter_group_name` | string | `default.valkey8` | パラメータグループ名 |
| `automatic_failover_enabled` | bool | `false` | 自動フェイルオーバー（`num_cache_clusters >= 2` が必要） |
| `multi_az_enabled` | bool | `false` | マルチ AZ（`automatic_failover_enabled = true` が必要） |
| `num_cache_clusters` | number | `1` | クラスター内ノード数（プライマリ + レプリカ） |
| `at_rest_encryption_enabled` | bool | `true` | 保存時の暗号化 |
| `transit_encryption_enabled` | bool | `true` | 転送中の暗号化 (TLS) |
| `kms_key_id` | string | `null` | 保存時暗号化用 KMS キー ARN（未指定時は AWS マネージドキー） |
| `auth_token` | string (sensitive) | `null` | AUTH トークン（`transit_encryption_enabled = true` が前提。TF_VAR で注入） |
| `snapshot_retention_limit` | number | `7` | 自動スナップショット保持日数（0 で無効） |
| `snapshot_window` | string | `17:00-18:00` | スナップショット取得時間帯 (UTC) |
| `maintenance_window` | string | `sun:18:00-sun:19:00` | メンテナンスウィンドウ (UTC) |
| `apply_immediately` | bool | `false` | 変更の即時適用 |

## tfvars の運用

- このリポジトリはテンプレート集のため、同梱するのは雛形の `sample.tfvars` のみ。テンプレートを実プロジェクトで採用する際に、環境別の `dev.tfvars` / `stg.tfvars` / `prod.tfvars` を `cp sample.tfvars <env>.tfvars` で作成し、そのままリポジトリにコミットする（`.gitignore` は tfvars を除外していない）。
- 環境別 tfvars がコミットされていれば Jenkins のクリーンチェックアウトにも含まれるため、`ENV` パラメータに応じた `-var-file="${ENV}.tfvars"` はそのまま動く。Config File Provider 等での外部注入は不要。
- **機密値（`auth_token` など）は tfvars に記載しない**。環境変数 `TF_VAR_auth_token` として注入する（値は Secrets Manager 等で管理）。

```sh
export TF_VAR_auth_token="$(aws secretsmanager get-secret-value --secret-id app/valkey/auth-token --query SecretString --output text)"
```

## memcached テンプレートとの対応関係

| 観点 | valkey (本テンプレート) | [aws-elasticache-memcached](../aws-elasticache-memcached/) |
| --- | --- | --- |
| リソース | `aws_elasticache_replication_group` | `aws_elasticache_cluster` |
| ノード数の変数 | `num_cache_clusters`（プライマリ + レプリカ） | `num_cache_nodes`（独立ノードの水平分割） |
| 冗長化 | `multi_az_enabled` / `automatic_failover_enabled` | `az_mode = "cross-az"`（フェイルオーバーなし） |
| 認証 | `auth_token`（AUTH） | なし |
| 暗号化 | 保存時 + 転送中 | 転送中のみ（1.6.12 以降） |
| スナップショット | あり（`snapshot_retention_limit` 等） | なし（データは揮発） |
| ポート | 6379 | 11211 |
