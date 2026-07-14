# コピーして <env>.tfvars (dev.tfvars / stg.tfvars / prod.tfvars) として利用する。
# 機密値はコミットせず、TF_VAR 環境変数や Secrets Manager で注入すること。
system_name = "app"
env         = "dev" # dev / stg / prod

# AWS→GCP 連携 (aws_to_gcp_service_accounts) を使う場合は必須
gcp_project_id = "my-gcp-project"

# ---------------------------------------------
# GCP → AWS (GCP の SA が AWS IAM ロールを AssumeRoleWithWebIdentity)
# 空マップ {} にするとこの方向のリソースは作成されない
# ---------------------------------------------
gcp_to_aws_roles = {
  # 新規作成 (既定)。ロール名は <system_name>-<env>-<キー> になる
  "gcp-batch" = {
    # SA の数値の一意 ID (メールアドレス不可)。gcloud iam service-accounts describe で確認できる
    gcp_service_account_unique_ids = ["111122223333444455556"]
    managed_policy_arns            = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
  }
  # 既存ロールにバインド (信頼ポリシーは output gcp_to_aws_required_trust_policies の JSON をロール側で設定する)
  # "existing-app" = {
  #   gcp_service_account_unique_ids = ["222233334444555566667"]
  #   create_role        = false
  #   existing_role_name = "app-dev-existing-role"
  # }
}

# ---------------------------------------------
# AWS → GCP (AWS の IAM ロールが GCP のサービスアカウントを impersonate)
# 空マップ {} にするとこの方向のリソースは作成されない
# ---------------------------------------------
aws_to_gcp_service_accounts = {
  # 既存 SA にバインド (既定)
  "deployer" = {
    email          = "deployer@my-gcp-project.iam.gserviceaccount.com"
    aws_role_names = ["app-dev-ecs-task"]
  }
  # SA も新規作成 (キーが account_id になる) + プロジェクトロール付与
  # "aws-reader" = {
  #   create         = true
  #   display_name   = "Federated from AWS"
  #   aws_role_names = ["app-dev-batch"]
  #   project_roles  = ["roles/storage.objectViewer"]
  # }
}

# 以下は default のままでよければ省略可
# region                      = "ap-northeast-1"
# default_tags                = {}
# google_oidc_audiences       = ["sts.amazonaws.com"]
# create_google_oidc_provider = true # アカウントに accounts.google.com の OIDC プロバイダが既にある場合は false
# aws_account_id              = null # 未指定なら実行中アカウントの ID を使用
