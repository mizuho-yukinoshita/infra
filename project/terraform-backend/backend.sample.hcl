bucket = "BUCKET_NAME"
region = "REGION"

# Jenkins から terraform init -backend-config で注入
# key = "${TerraformKey}/${ENV}/terraform.tfstate"

use_lockfile = true
encrypt      = true
