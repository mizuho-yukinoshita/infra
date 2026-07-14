output "google_oidc_provider_arn" {
  description = "Google OIDC プロバイダのARN (GCP→AWS 無効時は null)"
  value       = local.google_oidc_provider_arn
}

output "google_oidc_audiences" {
  description = "Google OIDC トークンの audience の既定値"
  value       = var.google_oidc_audiences
}

output "gcp_to_aws_role_arns" {
  description = "GCPから AssumeRoleWithWebIdentity できる IAM ロールのARN (作成・既存を合成)"
  value       = local.gcp_to_aws_role_arns
}

output "gcp_to_aws_required_trust_policies" {
  description = "create_role = false のエントリで、既存ロール側に設定が必要な信頼ポリシーJSON"
  value = {
    for k, v in var.gcp_to_aws_roles :
    k => data.aws_iam_policy_document.gcp_federated_trust[k].json if !v.create_role
  }
}

output "gcp_service_account_emails" {
  description = "AWSからの impersonate 対象GCPサービスアカウントのメールアドレス (作成・既存を合成)"
  value       = local.gcp_service_account_emails
}

output "workload_identity_pool_name" {
  description = "Workload Identity Pool の完全リソース名 (AWS→GCP 無効時は null)"
  value       = one(google_iam_workload_identity_pool.aws[*].name)
}

output "workload_identity_pool_provider_name" {
  description = "Workload Identity Pool プロバイダの完全リソース名。cred-config 生成にそのまま使用できる (AWS→GCP 無効時は null)"
  value       = one(google_iam_workload_identity_pool_provider.aws[*].name)
}

output "principal_set_uris" {
  description = "AWS IAM ロール名ごとの principalSet URI"
  value = local.aws_to_gcp_enabled ? {
    for r in local.allowed_aws_role_names :
    r => "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.aws[0].name}/attribute.aws_role/${r}"
  } : {}
}

output "gcloud_cred_config_commands" {
  description = "SAごとの認証構成ファイル生成コマンド例 (gcloud iam workload-identity-pools create-cred-config)"
  value = {
    for k, v in var.aws_to_gcp_service_accounts :
    k => "gcloud iam workload-identity-pools create-cred-config ${google_iam_workload_identity_pool_provider.aws[0].name} --service-account=${local.gcp_service_account_emails[k]} --aws --enable-imdsv2 --output-file=cred-config-${k}.json"
  }
}
