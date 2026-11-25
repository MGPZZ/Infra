# Thanos 지표 저장에 필요한 권한과 IRSA 설정
module "thanos_irsa" {
  source = "../../../modules/05-iam"

  role_name                  = "side-project-thanos-s3-role"
  policy_name                = "side-project-thanos-s3-policy"
  policy_description         = "IAM Policy for Thanos to access S3 metrics bucket"
  force_detach_policies      = true
  oidc_provider_arn          = module.side_project_eks.oidc_provider_arn
  namespace_service_accounts = ["monitoring:prometheus-stack-kube-prom-prometheus", "monitoring:thanos-store", "monitoring:thanos-query", "monitoring:thanos-compactor"]

  policy_statements = [
    {
      effect    = "Allow"
      actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
      resources = ["arn:aws:s3:::side-project-thanos-metrics-83154bf5"]
    },
    {
      effect    = "Allow"
      actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
      resources = ["arn:aws:s3:::side-project-thanos-metrics-83154bf5/*"]
    }
  ]
}

# 기존 환경 출력 이름 유지
output "thanos_irsa_role_arn" {
  description = "IAM Role ARN for Thanos IRSA"
  value       = module.thanos_irsa.iam_role_arn
}
