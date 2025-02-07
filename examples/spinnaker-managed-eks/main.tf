terraform {
  required_version = "~> 0.13.0"
}

provider "aws" {
  region = var.aws_region
}

# spinnaker managed eks
module "spinnaker-managed-eks" {
  source                    = "Young-ook/spinnaker/aws//modules/spinnaker-managed-eks"
  version                   = ">= 2.0"
  name                      = var.name
  stack                     = var.stack
  detail                    = var.detail
  tags                      = var.tags
  kubernetes_version        = var.kubernetes_version
  enabled_cluster_log_types = ["api", "audit"]
  managed_node_groups       = var.managed_node_groups
  enable_ssm                = var.enable_ssm
}

module "irsa" {
  source         = "Young-ook/eks/aws//modules/iam-role-for-serviceaccount"
  enabled        = false
  namespace      = "default"
  serviceaccount = "irsa-test"
  oidc_url       = module.spinnaker-managed-eks.oidc.url
  oidc_arn       = module.spinnaker-managed-eks.oidc.arn
  policy_arns    = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
  tags           = { env = "dev" }
}
