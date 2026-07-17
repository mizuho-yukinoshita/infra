plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.48.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "google" {
  enabled = true
  version = "0.39.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

# ElastiCache templates intentionally default to AWS default parameter groups;
# the value is variable-driven and overridable per environment.
rule "aws_elasticache_cluster_default_parameter_group" {
  enabled = false
}

rule "aws_elasticache_replication_group_default_parameter_group" {
  enabled = false
}
