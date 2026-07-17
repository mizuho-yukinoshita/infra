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

<!-- BEGIN_TF_DOCS -->
### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| env | 環境名 (dev, stg, prod) | `string` | n/a | yes |
| security\_group\_ids | 適用するセキュリティグループIDのリスト (プライベートサブネット内からのアクセスのみ許可すること) | `list(string)` | n/a | yes |
| subnet\_ids | ElastiCacheを配置するサブネットIDのリスト (プライベートサブネット必須) | `list(string)` | n/a | yes |
| system\_name | システム名 | `string` | n/a | yes |
| apply\_immediately | 変更を即時適用するか (false の場合は次回メンテナンスウィンドウで適用) | `bool` | `false` | no |
| at\_rest\_encryption\_enabled | 保存時の暗号化を有効にするか | `bool` | `true` | no |
| auth\_token | AUTHトークン (transit\_encryption\_enabled = true が前提)。tfvars には記載せず、環境変数 TF\_VAR\_auth\_token で注入すること | `string` | `null` | no |
| automatic\_failover\_enabled | 自動フェイルオーバーを有効にするか (*Requires num\_cache\_clusters >= 2) | `bool` | `false` | no |
| default\_tags | 全リソースに付与する追加タグ (固定タグにマージされる) | `map(string)` | `{}` | no |
| engine\_version | Valkeyエンジンのバージョン (v7以降は「メジャー.マイナー」形式のみ。例: 8.1) | `string` | `"8.1"` | no |
| kms\_key\_id | 保存時の暗号化に使用するKMSキーのARN (null の場合はAWSマネージドキーを使用) | `string` | `null` | no |
| maintenance\_window | メンテナンスウィンドウ (UTC)。例: sun:18:00-sun:19:00 (JST 月曜 3:00-4:00) | `string` | `"sun:18:00-sun:19:00"` | no |
| multi\_az\_enabled | マルチAZ配置を有効にするか (*Requires automatic\_failover\_enabled = true) | `bool` | `false` | no |
| node\_type | キャッシュノードのインスタンスタイプ | `string` | `"cache.t4g.micro"` | no |
| num\_cache\_clusters | クラスター内のノード数 | `number` | `1` | no |
| parameter\_group\_name | 適用するパラメータグループ名 | `string` | `"default.valkey8"` | no |
| region | AWSリージョン | `string` | `"ap-northeast-1"` | no |
| snapshot\_retention\_limit | 自動スナップショットの保持日数 (0 で自動スナップショット無効) | `number` | `7` | no |
| snapshot\_window | 自動スナップショットを取得する時間帯 (UTC)。maintenance\_window と重複しないこと | `string` | `"17:00-18:00"` | no |
| transit\_encryption\_enabled | 転送中の暗号化 (TLS) を有効にするか | `bool` | `true` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| valkey\_primary\_endpoint | Valkeyのプライマリエンドポイント |
| valkey\_reader\_endpoint | Valkeyの読み取り専用エンドポイント |
<!-- END_TF_DOCS -->

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
