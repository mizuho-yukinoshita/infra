# コピーして <env>.tfvars (dev.tfvars / stg.tfvars / prod.tfvars) として利用する。
# 機密値はコミットせず、TF_VAR 環境変数や Secrets Manager で注入すること。
system_name = "app"
env         = "dev" # dev / stg / prod

gcp_project_id = "my-gcp-project"

# ---------------------------------------------
# バケット定義
# 空マップ {} にするとリソースは作成されない
# バケット名は既定で <system_name>-<env>-<キー> になる (グローバル一意必須)
# ---------------------------------------------
buckets = {
  # バージョニング + ライフサイクル付きバケット
  "assets" = {
    versioning = true
    lifecycle_rules = [
      # 90 日経過したライブオブジェクトを削除
      {
        action     = "Delete"
        age_days   = 90
        with_state = "LIVE"
      },
      # 非カレント (旧世代) バージョンを新しい 3 世代だけ残して削除
      {
        action             = "Delete"
        num_newer_versions = 3
        with_state         = "ARCHIVED"
      },
    ]
    # 既定名がグローバル一意にならない場合はバケット名を明示指定する
    # name = "my-unique-app-dev-assets"
    # CMEK を使う場合のみ指定 (SA への roles/cloudkms.cryptoKeyEncrypterDecrypter 付与が別途必要)
    # kms_key_name = "projects/my-gcp-project/locations/asia-northeast1/keyRings/my-keyring/cryptoKeys/my-key"
  }
  # IAM 付与つきバケット (ロール => メンバーのリスト)
  "logs" = {
    storage_class = "NEARLINE"
    iam_members = {
      "roles/storage.objectUser" = [
        "serviceAccount:app-writer@my-gcp-project.iam.gserviceaccount.com",
      ]
    }
    # 365 日経過でストレージクラスを COLDLINE に変更する例
    # lifecycle_rules = [
    #   {
    #     action        = "SetStorageClass"
    #     storage_class = "COLDLINE"
    #     age_days      = 365
    #   },
    # ]
  }
}

# 以下は default のままでよければ省略可
# location       = "asia-northeast1"
# default_labels = {} # 全バケット共通の追加ラベル (英小文字・数字・- _ のみ)
