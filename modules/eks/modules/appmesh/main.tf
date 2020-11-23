## kubernetes appmesh

locals {
  namespace      = lookup(var.helm, "namespace", "appmesh-system")
  serviceaccount = lookup(var.helm, "serviceaccount", "aws-appmesh-controller")
}

module "irsa" {
  source         = "../../../iam-role-for-serviceaccount"
  count          = var.enabled ? 1 : 0
  namespace      = local.namespace
  serviceaccount = local.serviceaccount
  oidc_url       = var.oidc.url
  oidc_arn       = var.oidc.arn
  policy_arns = [
    format("arn:%s:iam::aws:policy/AWSCloudMapFullAccess", data.aws_partition.current.partition),
    format("arn:%s:iam::aws:policy/AWSAppMeshFullAccess", data.aws_partition.current.partition),
  ]
  tags = var.tags
}

resource "helm_release" "appmesh" {
  count            = var.enabled ? 1 : 0
  name             = lookup(var.helm, "name", "eks-am")
  chart            = lookup(var.helm, "chart")
  repository       = lookup(var.helm, "repository")
  namespace        = local.namespace
  create_namespace = true
  cleanup_on_fail  = lookup(var.helm, "cleanup_on_fail", true)

  dynamic "set" {
    for_each = {
      "region"                                                    = data.aws_region.current.name
      "serviceAccount.name"                                       = local.serviceaccount
      "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = module.irsa[0].arn[0]
      "tracing.enabled"                                           = true
      "tracing.provider"                                          = "x-ray"
    }
    content {
      name  = set.key
      value = set.value
    }
  }
}