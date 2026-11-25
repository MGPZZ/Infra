output "default_route_ids" {
  description = "프라이빗 서브넷 연결 전에 생성할 AZ별 기본 NAT 경로 ID"
  value       = { for az, route in aws_route.private_nat_default : az => route.id }
}

output "probe_targets" {
  description = "Blackbox와 Controller에 전달할 IPv4:포트 목록"
  value = {
    service  = [for target in var.probe_targets.service : "${target.ip}:${target.port}"]
    recovery = ["${var.probe_targets.recovery.ip}:${var.probe_targets.recovery.port}"]
  }
}
