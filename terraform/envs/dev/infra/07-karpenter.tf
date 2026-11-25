##########################################
# 9. Karpenter 인프라 (IAM & SQS)
##########################################
module "karpenter" {
  source = "../../../modules/11-karpenter_setup"

  cluster_name      = module.side_project_eks.cluster_name
  oidc_provider_arn = module.side_project_eks.oidc_provider_arn
}
# 기존 Karpenter Controller 역할에 필요한 추가 권한 정의
module "karpenter_iam" {
  source = "../../../modules/05-iam"

  create_role = false
  role_name   = basename(module.karpenter.iam_role_arn)
  policy_name = "karpenter-list-instance-profiles"

  policy_statements = [
    {
      effect    = "Allow"
      actions   = ["iam:ListInstanceProfiles"]
      resources = ["*"]
      sid       = "AllowListInstanceProfiles"
    },
    {
      effect    = "Allow"
      actions   = ["iam:CreateServiceLinkedRole"]
      resources = ["arn:aws:iam::*:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot"]
      sid       = "AllowCreateSpotServiceLinkedRole"
      condition = [
        {
          test     = "StringEquals"
          variable = "iam:AWSServiceName"
          values   = ["spot.amazonaws.com"]
        }
      ]
    }
  ]
}

resource "helm_release" "karpenter" {
  namespace  = "kube-system"
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.14.0"

  set {
    name  = "settings.clusterName"
    value = module.side_project_eks.cluster_name
  }

  set {
    name  = "settings.interruptionQueue"
    value = module.karpenter.queue_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.iam_role_arn
  }

  # Karpenter 파드를 어느 노드에 띄울지 지정
  set {
    name  = "nodeSelector.role"
    value = "management"
  }
  set {
    name  = "replicas"
    value = "2"
  }
  set {
    name  = "settings.featureGates.nodeRepair"
    value = "true"
  }
  # Service account 이름 karpenter 고정
  set {
    name  = "serviceAccount.name"
    value = "karpenter"
  }
  depends_on = [module.karpenter, module.karpenter_iam, module.side_project_eks]
}
