# No credentials in code: ADC (Application Default Credentials) is assumed.
# default_labels mirrors the aws default_tags pattern; GCS labels only allow
# lowercase letters, numbers, hyphens, and underscores.
provider "google" {
  project = var.gcp_project_id

  default_labels = merge(
    {
      terraform-key = "storage--gcp-cloud-storage"
      system-name   = var.system_name
      environment   = var.env
      managed-by    = "terraform"
    },
    var.default_labels
  )
}

resource "google_storage_bucket" "this" {
  for_each = var.buckets

  name          = coalesce(each.value.name, "${var.system_name}-${var.env}-${each.key}")
  location      = coalesce(each.value.location, var.location)
  storage_class = each.value.storage_class
  force_destroy = each.value.force_destroy

  # Fixed on purpose: disables ACLs entirely so access is governed by IAM only
  uniform_bucket_level_access = true
  public_access_prevention    = each.value.public_access_prevention

  versioning {
    enabled = each.value.versioning
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules

    content {
      action {
        type          = lifecycle_rule.value.action
        storage_class = lifecycle_rule.value.storage_class
      }

      # Null attributes are treated as unset, so only the specified
      # conditions take effect
      condition {
        age                = lifecycle_rule.value.age_days
        num_newer_versions = lifecycle_rule.value.num_newer_versions
        with_state         = lifecycle_rule.value.with_state
      }
    }
  }

  dynamic "encryption" {
    for_each = each.value.kms_key_name != null ? [each.value.kms_key_name] : []

    content {
      default_kms_key_name = encryption.value
    }
  }

  # Per-bucket extras only; common labels come from provider default_labels
  labels = each.value.labels
}

locals {
  bucket_iam_members = {
    for b in flatten([
      for bucket_key, bucket in var.buckets : [
        for role, members in bucket.iam_members : [
          for member in members : {
            bucket_key = bucket_key
            role       = role
            member     = member
          }
        ]
      ]
    ]) : "${b.bucket_key}|${b.role}|${b.member}" => b
  }
}

# iam_member (not binding/policy) so that grants managed elsewhere survive
resource "google_storage_bucket_iam_member" "this" {
  for_each = local.bucket_iam_members

  bucket = google_storage_bucket.this[each.value.bucket_key].name
  role   = each.value.role
  member = each.value.member
}
