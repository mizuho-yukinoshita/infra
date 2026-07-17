# queue/aws-sqs

AWS SQS の標準キュー（メインキュー + デッドレターキュー）を作成する Terraform テンプレート。

## 構成

- **メインキュー**: SSE (SQS マネージド) 有効。`max_receive_count` 回受信されて処理されなかったメッセージは DLQ へ移動する（redrive policy）。
- **DLQ**: `redrive_allow_policy` によりメインキューからのみ redrive を受け付ける（`byQueue`）。
- **キューポリシー**: `operation_iam_path` で指定した IAM プリンシパルに対し、送受信・削除など運用に必要な最小限のアクションのみ許可。

### DLQ の保持期間の考え方

DLQ のメッセージ保持期間はデフォルトで最大の 14 日（メインキューは 7 日）。
DLQ に入った時点で元のエンキュー時刻からの経過時間が引き継がれるため、
調査・再処理の猶予を確保するには DLQ 側をメインキューより長くしておく必要がある
（variables.tf の validation で強制）。

## 変数一覧

<!-- BEGIN_TF_DOCS -->
### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| env | 環境名 (dev / stg / prod) | `string` | n/a | yes |
| operation\_iam\_path | SQSキューの操作を許可するIAMのパス (例: role/sqs-operator) | `string` | n/a | yes |
| system\_name | システム名 | `string` | n/a | yes |
| default\_tags | 全リソースに付与する追加タグ | `map(string)` | `{}` | no |
| dlq\_message\_retention\_seconds | DLQのメッセージ保持期間 (秒)。調査猶予を確保するためメインキューより長くする | `number` | `1209600` | no |
| dlq\_visibility\_timeout\_seconds | DLQの可視性タイムアウト (秒) | `number` | `30` | no |
| main\_message\_retention\_seconds | メインキューのメッセージ保持期間 (秒) | `number` | `604800` | no |
| main\_visibility\_timeout\_seconds | メインキューの可視性タイムアウト (秒) | `number` | `20` | no |
| max\_receive\_count | メインキューでの最大受信回数。超過したメッセージはDLQへ移動する | `number` | `3` | no |
| region | AWSリージョン | `string` | `"ap-northeast-1"` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| dl\_queue\_arn | デッドレターキュー(DLQ)のARN |
| dl\_queue\_url | デッドレターキュー(DLQ)のURL |
| main\_queue\_arn | メインキューのARN |
| main\_queue\_url | メインキューのURL |
<!-- END_TF_DOCS -->

## tfvars 運用

- このリポジトリはテンプレート集のため、同梱するのは雛形の `sample.tfvars` のみ。テンプレートを実プロジェクトで採用する際に、環境別の `dev.tfvars` / `stg.tfvars` / `prod.tfvars` を `cp sample.tfvars <env>.tfvars` で作成し、そのままリポジトリにコミットする（`.gitignore` は tfvars を除外していない）。
- 環境別 tfvars がコミットされていれば Jenkins のクリーンチェックアウトにも含まれるため、`Jenkinsfile` の `-var-file="${ENV}.tfvars"` はそのまま動く。Config File Provider 等での外部注入は不要。
- 機密値は tfvars に書かず、`TF_VAR_xxx` 環境変数や Secrets Manager で注入する。

## state の key 規約

backend は S3。key は Jenkins が生成する `backend.hcl` 経由で
`queue/aws-sqs/${ENV}/terraform.tfstate` として渡す（versions.tf の backend ブロックには書かない）。
