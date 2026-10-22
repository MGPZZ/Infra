############################################
# 11. CloudNativePG (CNPG) Operator 배포
############################################

resource "helm_release" "cnpg_operator" {
  name             = "cnpg"
  repository       = "https://cloudnative-pg.github.io/charts"
  chart            = "cloudnative-pg"
  version          = "0.21.5"
  namespace        = "cnpg-system"
  create_namespace = true
  values = [<<-YAML
    nodeSelector:
      role: management
    YAML
  ]

  # CNPG creates Services, which pass through the AWS LBC admission webhook.
  depends_on = [helm_release.aws_lb_controller]
}
