# aws-elasticache-memcached

ElastiCache for Memcached のクラスターを構築する Terraform テンプレート。
永続化やレプリケーションが不要な、シンプルな揮発キャッシュ用途で使用する（データはノード障害時に失われる）。

## 前提リソース

- VPC / プライベートサブネット（`subnet_ids` にはプライベートサブネットのみ指定すること）
- セキュリティグループ（アプリケーションからポート 11211 へのインバウンドを許可したもの）
- Terraform backend 用 S3 バケット（CloudFormation スタック `terraform-backend` で作成済みであること）

## backend / state キー規約

backend の `bucket` / `region` / `key` は Jenkins が生成する `backend.hcl` から注入する。

```
key = "database/aws-elasticache-memcached/${ENV}/terraform.tfstate"
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
| `engine_version` | string | `1.6.22` | エンジンバージョン |
| `node_type` | string | `cache.t4g.micro` | ノードのインスタンスタイプ |
| `parameter_group_name` | string | `default.memcached1.6` | パラメータグループ名 |
| `num_cache_nodes` | number | `1` | ノード数（各ノードは独立、データは分散配置） |
| `az_mode` | string | `single-az` | AZ 配置モード。`num_cache_nodes > 1` の場合は `cross-az` を推奨 |
| `transit_encryption_enabled` | bool | `true` | 転送中の暗号化 (TLS)。Memcached 1.6.12 以降が前提 |
| `maintenance_window` | string | `sun:18:00-sun:19:00` | メンテナンスウィンドウ (UTC) |

## tfvars の運用

- このリポジトリはテンプレート集のため、同梱するのは雛形の `sample.tfvars` のみ。テンプレートを実プロジェクトで採用する際に、環境別の `dev.tfvars` / `stg.tfvars` / `prod.tfvars` を `cp sample.tfvars <env>.tfvars` で作成し、そのままリポジトリにコミットする（`.gitignore` は tfvars を除外していない）。
- 環境別 tfvars がコミットされていれば Jenkins のクリーンチェックアウトにも含まれるため、`ENV` パラメータに応じた `-var-file="${ENV}.tfvars"` はそのまま動く。Config File Provider 等での外部注入は不要。
- 機密値が必要になった場合は tfvars に記載せず、環境変数 `TF_VAR_<変数名>` で注入する（値は Secrets Manager 等で管理）。本テンプレートには現状 sensitive な変数はない。

## valkey テンプレートとの対応関係

| 観点 | memcached (本テンプレート) | [aws-elasticache-valkey](../aws-elasticache-valkey/) |
| --- | --- | --- |
| リソース | `aws_elasticache_cluster` | `aws_elasticache_replication_group` |
| ノード数の変数 | `num_cache_nodes`（独立ノードの水平分割） | `num_cache_clusters`（プライマリ + レプリカ） |
| 冗長化 | `az_mode = "cross-az"`（フェイルオーバーなし） | `multi_az_enabled` / `automatic_failover_enabled` |
| 認証 | なし | `auth_token`（AUTH） |
| 暗号化 | 転送中のみ（1.6.12 以降） | 保存時 + 転送中 |
| スナップショット | なし（データは揮発） | あり（`snapshot_retention_limit` 等） |
| ポート | 11211 | 6379 |
