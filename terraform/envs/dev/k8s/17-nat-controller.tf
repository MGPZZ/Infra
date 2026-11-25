# Secrets Manager에 등록한 웹훅 토큰을 배포 시 조회
data "aws_secretsmanager_secret" "nat_controller_webhook" {
  name = "side-project/nat-controller/webhook-token"
}

data "aws_secretsmanager_secret_version" "nat_controller_webhook" {
  secret_id = data.aws_secretsmanager_secret.nat_controller_webhook.id
}

# 기존 namespace가 있으면 재사용하고 destroy 시에도 남겨둔다.
resource "kubectl_manifest" "nat_controller_namespace" {
  for_each = toset(["monitoring", "manage"])

  server_side_apply = true
  apply_only        = true
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Namespace"
    metadata   = { name = each.key }
  })
}

# 양쪽 Pod가 자기 namespace에서 동일한 토큰을 참조
resource "kubernetes_secret_v1" "nat_controller_webhook" {
  for_each = kubectl_manifest.nat_controller_namespace

  metadata {
    name      = "nat-controller-webhook"
    namespace = each.value.name
  }

  data = {
    token = trimspace(jsondecode(data.aws_secretsmanager_secret_version.nat_controller_webhook.secret_string)["token"])
  }
}

# 재부팅 요청 여부는 Controller가 갱신하고 Terraform은 보존한다.
resource "kubernetes_config_map_v1" "nat_controller_state" {
  metadata {
    name      = "nat-controller-state"
    namespace = kubectl_manifest.nat_controller_namespace["manage"].name
  }

  lifecycle {
    ignore_changes = [data]
  }
}
