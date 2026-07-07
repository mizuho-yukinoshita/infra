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

| 変数名 | 説明 | 型 | デフォルト |
|---|---|---|---|
| `system_name` | システム名 | string | (必須) |
| `env` | 環境名 (dev / stg / prod) | string | (必須) |
| `operation_iam_path` | キュー操作を許可する IAM のパス (例: `role/sqs-operator`) | string | (必須) |
| `region` | AWS リージョン | string | `ap-northeast-1` |
| `default_tags` | 全リソースに付与する追加タグ | map(string) | `{}` |
| `main_visibility_timeout_seconds` | メインキューの可視性タイムアウト (秒) | number | `20` |
| `main_message_retention_seconds` | メインキューのメッセージ保持期間 (秒) | number | `604800` (7日) |
| `dlq_visibility_timeout_seconds` | DLQ の可視性タイムアウト (秒) | number | `30` |
| `dlq_message_retention_seconds` | DLQ のメッセージ保持期間 (秒) | number | `1209600` (14日) |
| `max_receive_count` | DLQ へ移動するまでの最大受信回数 | number | `3` |

## tfvars 運用

- このリポジトリはテンプレート集のため、同梱するのは雛形の `sample.tfvars` のみ。テンプレートを実プロジェクトで採用する際に、環境別の `dev.tfvars` / `stg.tfvars` / `prod.tfvars` を `cp sample.tfvars <env>.tfvars` で作成し、そのままリポジトリにコミットする（`.gitignore` は tfvars を除外していない）。
- 環境別 tfvars がコミットされていれば Jenkins のクリーンチェックアウトにも含まれるため、`Jenkinsfile` の `-var-file="${ENV}.tfvars"` はそのまま動く。Config File Provider 等での外部注入は不要。
- 機密値は tfvars に書かず、`TF_VAR_xxx` 環境変数や Secrets Manager で注入する。

## state の key 規約

backend は S3。key は Jenkins が生成する `backend.hcl` 経由で
`queue/aws-sqs/${ENV}/terraform.tfstate` として渡す（versions.tf の backend ブロックには書かない）。
