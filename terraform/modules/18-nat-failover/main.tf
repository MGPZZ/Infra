resource "aws_route" "private_nat_default" {
  for_each = var.nat_targets

  route_table_id         = each.value.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = each.value.network_interface_id

  lifecycle {
    # NAT Controller가 장애 시 기본 경로의 대상을 전환한다.
    ignore_changes = [network_interface_id]
  }
}

# 기본 경로를 전환해도 복구 검사는 각 AZ의 원래 NAT를 통과한다.
resource "aws_route" "nat_recovery_probe" {
  # 기존 Terraform 리소스 주소의 AZ:IP 키를 유지한다.
  for_each = {
    for az, target in var.nat_targets : "${az}:${var.probe_targets.recovery.ip}" => target
  }

  route_table_id         = each.value.route_table_id
  destination_cidr_block = "${var.probe_targets.recovery.ip}/32"
  network_interface_id   = each.value.network_interface_id
}
