# ############################################
# # 6. ALB (Public Load Balancer)
# ############################################


data "aws_acm_certificate" "this" {
  domain   = var.domain_name
  statuses = ["ISSUED"]
}
# CRD/컨트롤러 이후 기본 세팅 =================
resource "kubectl_manifest" "gatewayclass" {
  wait       = true
  yaml_body  = file("${path.module}/gateway_api/gatewayclass.yaml")
  depends_on = [kubectl_manifest.gateway_api_crds, helm_release.aws_lb_controller]
}

resource "kubectl_manifest" "lb_config" {
  wait = true
  yaml_body = templatefile("${path.module}/gateway_api/loadbalancerconfigure.yaml", {
    certificate_arn = data.aws_acm_certificate.this.arn
  })
  depends_on = [kubectl_manifest.lbc_gateway_crds, helm_release.aws_lb_controller]
}
# gateway 생성 => alb 생성 ===================
resource "kubectl_manifest" "gateway" {
  yaml_body = file("${path.module}/gateway_api/gateway.yaml")

  # 이 gateway 리소스(alb)를 삭제할 때 까지 기다리게 해주는 부분
  wait = true

  wait_for {
    condition {
      type   = "Programmed"
      status = "True"
    }

    field {
      key        = "status.addresses[0].value"
      value      = ".+"
      value_type = "regex"
    }
  }

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }

  depends_on = [
    kubectl_manifest.gatewayclass,
    kubectl_manifest.lb_config
  ]
}

# alb arn, host zone id 등 필요한 정보를 얻어내기 위해 data 사용
data "aws_lb" "this" {
  name       = "side-project-alb"
  depends_on = [kubectl_manifest.gateway]

  lifecycle {
    postcondition {
      condition     = self.vpc_id == data.terraform_remote_state.infra.outputs.vpc_id
      error_message = "side-project-alb exists in a different VPC. Remove the stale ALB/target groups before provisioning this environment."
    }
  }
}
