# 사용 중인 LB Controller 버전의 공식 권한 정책 조회
data "http" "aws_lb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.4.0/docs/install/iam_policy.json"
}

# LB Controller에 필요한 정책과 IRSA 설정 전달
module "aws_lb_controller_iam" {
  source = "../../../modules/05-iam"

  role_name                  = "${module.side_project_eks.cluster_name}-aws-lb-controller"
  policy_name                = "${module.side_project_eks.cluster_name}-aws-lb-controller"
  policy_description         = "IAM policy for AWS Load Balancer Controller"
  policy_json                = data.http.aws_lb_controller_policy.response_body
  oidc_provider_arn          = module.side_project_eks.oidc_provider_arn
  namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
}
