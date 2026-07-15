# storage/gcp-cloud-storage

Google Cloud Storage (GCS) バケットを作成する Terraform テンプレート。

## 構成

- `buckets` マップの 1 エントリにつき 1 バケット (`google_storage_bucket`) を作成する。
  - バケット名は既定で `<system_name>-<env>-<キー>`。グローバル一意にならない場合は `name` で明示指定できる
  - ロケーションは既定で `var.location`（デフォルト `asia-northeast1`）。エントリごとに `location` で上書き可能
  - ストレージクラス・バージョニング・ライフサイクルルール・CMEK（`kms_key_name`）をエントリごとに設定できる
- `iam_members` で「ロール => メンバーのリスト」のバケットレベル IAM 付与 (`google_storage_bucket_iam_member`) ができる。
- 共通ラベル（`terraform-key` / `system-name` / `environment` / `managed-by` + `default_labels`）はプロバイダの `default_labels` で全バケットに付与し、エントリごとの `labels` は追加分のみ指定する。
- **`buckets = {}` ならリソースは一切作成されない**（作成リソース 0）。

## 前提条件

### GCP 側

- 対象プロジェクトで以下の API を有効化しておく:
  - `storage.googleapis.com`
- Terraform 実行者（ADC のプリンシパル）に必要な権限:
  - バケットの作成・削除と IAM 設定: `roles/storage.admin` 相当
  - CMEK（`kms_key_name`）を使う場合: 対象鍵に対して GCS サービスエージェントへ `roles/cloudkms.cryptoKeyEncrypterDecrypter` を付与しておくこと（本テンプレートでは付与しない）
- 認証はコードに書かず ADC（Application Default Credentials）を使用する。ローカルでは `gcloud auth application-default login`、Jenkins では後述の Secret file を利用。

### AWS 側

- state backend は S3 のため、backend 用の AWS 認証（`AWS_PROFILE`）と `terraform-backend` スタックが必要（GCS リソース自体に AWS 認証は使用しない）。

## 変数一覧

| 変数名 | 説明 | 型 | デフォルト |
|---|---|---|---|
| `system_name` | システム名 | string | (必須) |
| `env` | 環境名 (dev / stg / prod) | string | (必須) |
| `gcp_project_id` | GCP プロジェクト ID | string | (必須) |
| `location` | バケットのデフォルトロケーション | string | `asia-northeast1` |
| `default_labels` | 全バケットに付与する追加ラベル（英小文字・数字・`-` `_` のみ） | map(string) | `{}` |
| `buckets` | 作成するバケットの定義（下表） | map(object) | `{}` |

### buckets のエントリ

| 属性 | 説明 | デフォルト |
|---|---|---|
| `name` | バケット名の明示指定（null なら `<system_name>-<env>-<キー>`） | `null` |
| `location` | ロケーション（null なら `var.location`） | `null` |
| `storage_class` | ストレージクラス（STANDARD / NEARLINE / COLDLINE / ARCHIVE） | `STANDARD` |
| `versioning` | オブジェクトバージョニングを有効にするか | `false` |
| `force_destroy` | destroy 時にオブジェクトごと削除するか | `false` |
| `public_access_prevention` | 公開アクセス防止（`enforced` / `inherited`） | `enforced` |
| `kms_key_name` | CMEK の鍵リソース名（使う場合のみ） | `null` |
| `lifecycle_rules` | ライフサイクルルールのリスト（下表） | `[]` |
| `iam_members` | ロール => メンバーのリスト（例: `"roles/storage.objectUser" => ["serviceAccount:..."]`） | `{}` |
| `labels` | このバケットのみに付与する追加ラベル | `{}` |

### lifecycle_rules のエントリ

| 属性 | 説明 | デフォルト |
|---|---|---|
| `action` | `Delete` または `SetStorageClass` | (必須) |
| `storage_class` | 変更先ストレージクラス（`action = SetStorageClass` のとき必須） | `null` |
| `age_days` | オブジェクト作成からの経過日数 | `null` |
| `num_newer_versions` | 残す新しい世代数（これより古い非カレント版が対象） | `null` |
| `with_state` | 対象オブジェクトの状態（`LIVE` / `ARCHIVED` / `ANY`） | `null` |

## 利用方法

1. `cp sample.tfvars <env>.tfvars` で環境別 tfvars を作成し、バケット定義を記述してリポジトリにコミットする（`.gitignore` は tfvars を除外していない）。
2. 本テンプレートの `Jenkinsfile` を指す Jenkins Pipeline ジョブを作成し、`ENV` / `ACTION` / `AWS_PROFILE` 等のパラメータを指定して実行する。
3. plan 結果を確認して承認すると apply される。

### Jenkins の GCP 認証設定

- Jenkins の **Secret file** クレデンシャルとして GCP サービスアカウントキー（JSON）を登録し、ジョブパラメータ `GCP_CREDENTIALS_ID` にそのクレデンシャル ID を指定すると、パイプラインが `GOOGLE_APPLICATION_CREDENTIALS` として注入する（鍵ファイルはワークスペースに書き出されない）。
- `GCP_CREDENTIALS_ID` が空の場合はエージェントの ADC をそのまま使用する。

## セキュリティ既定値

- **`uniform_bucket_level_access = true` に固定**: オブジェクト ACL を全面無効化し、アクセス制御を IAM に一本化する。ACL 併用によるアクセス経路の見落としを防ぐため変数化していない。
- **`public_access_prevention` は既定で `enforced`**: 誤設定によるバケットの公開を防止する。組織ポリシー側の設定に委ねたい場合のみ `inherited` を指定する。
- **IAM 付与は `google_storage_bucket_iam_member`（追加型）を使用**: binding / policy 型と異なり、他のテンプレートやコンソールで管理されている既存の付与を上書き・削除しない。

## バケット名のグローバル一意性

GCS のバケット名は**全世界で一意**である必要がある。既定の `<system_name>-<env>-<キー>` は他プロジェクト・他組織のバケットと衝突する可能性があるため、衝突した場合はエントリの `name` で一意な名前（プロジェクト ID を含める等）を明示指定する。

## destroy 時の注意

- `force_destroy = false`（既定）のバケットは、**オブジェクトが残っていると削除に失敗する**。destroy する場合は事前にオブジェクトを削除するか、`force_destroy = true` を設定して apply してから destroy する。
- 削除したバケットの名前は**削除後も一定期間再利用できない**ことがある。destroy → 即 apply のやり直しで同名バケットの作成に失敗する場合は時間を置くか別名にする。

## tfvars 運用

- このリポジトリはテンプレート集のため、同梱するのは雛形の `sample.tfvars` のみ。テンプレートを実プロジェクトで採用する際に、環境別の `dev.tfvars` / `stg.tfvars` / `prod.tfvars` を `cp sample.tfvars <env>.tfvars` で作成し、そのままリポジトリにコミットする。
- 機密値は tfvars に書かず、`TF_VAR_xxx` 環境変数や Secrets Manager で注入する（GCP サービスアカウントキーは Jenkins の Secret file を使用）。

## state の key 規約

backend は S3。key は Jenkins が生成する `backend.hcl` 経由で
`storage/gcp-cloud-storage/${ENV}/terraform.tfstate` として渡す（versions.tf の backend ブロックには書かない）。
