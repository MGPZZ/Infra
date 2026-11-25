# CNPG 백업에 필요한 권한과 IRSA 설정
module "cnpg_irsa" {
  source = "../../../modules/05-iam"

  role_name                  = "side-project-cnpg-s3-role"
  policy_name                = "side-project-cnpg-s3-policy"
  policy_description         = "IAM Policy for CNPG to access S3 backup bucket"
  force_detach_policies      = true
  oidc_provider_arn          = module.side_project_eks.oidc_provider_arn
  namespace_service_accounts = ["backend:side-project-db", "finops:krr-data-db"]

  policy_statements = [
    {
      effect    = "Allow"
      actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
      resources = ["arn:aws:s3:::side-project-cnpg-backup-07l03u", "arn:aws:s3:::side-project-cnpg-backup-07l03u/*"]
    }
  ]
}
