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

<!-- BEGIN_TF_DOCS -->
### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| env | 環境名 (dev, stg, prod) | `string` | n/a | yes |
| security\_group\_ids | 適用するセキュリティグループIDのリスト | `list(string)` | n/a | yes |
| system\_name | システム名 | `string` | n/a | yes |
| writer\_instance\_class | Writer（マスター）のインスタンスクラス | `string` | n/a | yes |
| backup\_retention\_period | 自動バックアップの保持期間（日） | `number` | `7` | no |
| cluster\_parameter\_group\_family | 自前で作成するクラスターパラメータグループのファミリー | `string` | `"aurora-mysql8.0"` | no |
| cluster\_parameter\_group\_name | （既存を利用する場合）クラスターパラメータグループ名。null または "" の場合は自前で作成する | `string` | `null` | no |
| cluster\_parameters | クラスターパラメータのリスト | <pre>list(object({<br/>    name         = string<br/>    value        = string<br/>    apply_method = string<br/>  }))</pre> | `[]` | no |
| cluster\_tags | クラスターに付与するタグ | `map(string)` | `{}` | no |
| copy\_tags\_to\_snapshot | スナップショットにタグをコピーするか | `bool` | `true` | no |
| db\_parameter\_group\_family | 自前で作成するインスタンスパラメータグループのファミリー | `string` | `"aurora-mysql8.0"` | no |
| db\_parameter\_group\_name | （既存を利用する場合）インスタンスパラメータグループ名。null または "" の場合は自前で作成する | `string` | `null` | no |
| db\_parameters | インスタンスパラメータのリスト | <pre>list(object({<br/>    name         = string<br/>    value        = string<br/>    apply_method = string<br/>  }))</pre> | `[]` | no |
| default\_tags | リソースに付与する共通タグ | `map(string)` | `{}` | no |
| delete\_automated\_backups | クラスター削除時に自動バックアップも削除するか | `bool` | `true` | no |
| deletion\_protection | クラスターの削除保護を有効にするか | `bool` | `true` | no |
| enabled\_cloudwatch\_logs\_exports | CloudWatchへエクスポートするログの種類 | `list(string)` | `[]` | no |
| engine\_version | Aurora MySQLのエンジンバージョン | `string` | `"8.0.mysql_aurora.3.10.2"` | no |
| final\_snapshot\_identifier | 最終スナップショットの識別子（skip\_final\_snapshot = false の場合に必須） | `string` | `null` | no |
| is\_route53\_zone\_private | Route 53のホストゾーンがプライベート（VPC内のみ）かどうか | `bool` | `true` | no |
| kms\_key\_id | 暗号化に使用するKMSキーのARN（未指定の場合はAWSマネージドキーを使用） | `string` | `null` | no |
| manage\_master\_password | AWS Secrets Managerによるマスターパスワードの自動管理を有効にするか（推奨: true） | `bool` | `true` | no |
| master\_password | マスターパスワード（manage\_master\_password = false の場合のみ使用）。tfvars には書かず、環境変数 TF\_VAR\_master\_password で注入すること | `string` | `null` | no |
| master\_username | マスターユーザー名 | `string` | `"admin"` | no |
| performance\_insights\_enabled | Performance Insightsを有効にするか | `bool` | `false` | no |
| performance\_insights\_retention\_period | Performance Insightsのデータ保持期間（日） | `number` | `7` | no |
| preferred\_backup\_window | 自動バックアップを実行する時間帯（UTC） | `string` | `"19:30-20:59"` | no |
| preferred\_maintenance\_window | メンテナンスを実行する時間帯（UTC） | `string` | `"sat:20:30-sat:20:59"` | no |
| reader\_count | 作成するReaderの台数（0なら作らない） | `number` | `0` | no |
| reader\_instance\_class | Reader（リードレプリカ）のインスタンスクラス | `string` | `null` | no |
| reader\_tags | Readerに付与するタグ | `map(string)` | `{}` | no |
| region | AWSリージョン | `string` | `"ap-northeast-1"` | no |
| route53\_record\_name | Route 53のレコード名。指定しない場合は${system\_name}-${env}-db | `string` | `null` | no |
| route53\_zone\_name | クラスターエンドポイントのレコードを追加するRoute 53のホストゾーン名 | `string` | `null` | no |
| serverless\_max\_capacity | Serverless v2の最大ACU（0の場合はServerless設定を行わない） | `number` | `0` | no |
| serverless\_min\_capacity | Serverless v2の最小ACU | `number` | `0` | no |
| skip\_final\_snapshot | クラスター削除時に最終スナップショットの取得をスキップするか（prodではfalse推奨） | `bool` | `true` | no |
| storage\_encrypted | ストレージの暗号化を有効にするか | `bool` | `true` | no |
| subnet\_group\_name | DBサブネットグループ名 | `string` | `null` | no |
| writer\_tags | Writerに付与するタグ | `map(string)` | `{}` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| cluster\_endpoint | 作成したAuroraクラスターの Write/Read エンドポイント |
| cluster\_port | 作成したAuroraクラスターのポート番号 |
| cluster\_ro\_endpoint | 作成したAuroraクラスターの ReadOnly エンドポイント |
<!-- END_TF_DOCS -->

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
